# Runs manifest hooks ONLY against a TestDrive model, mocked registry/filesystem,
# mocked Scoop elevation helper, and a managed native API double with NO DllImport.
Describe 'Isolated font lifecycle model (not Windows integration)' {
    BeforeAll {
        $m = Get-Content (Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json') -Raw | ConvertFrom-Json
        $install = [scriptblock]::Create($m.installer.script -join "`n")
        $uninstall = [scriptblock]::Create($m.uninstaller.script -join "`n")
        function is_admin { throw 'Must be mocked' }
        if ('ScoopFlagEmojiNativeV2' -as [type]) { throw 'Native type already loaded; run tests in a fresh PowerShell process.' }
        Add-Type @'
using System;
public static class ScoopFlagEmojiNativeV2 {
    public static int AddResult = 1, Adds = 0, Removes = 0, Notifications = 0;
    public static int AddFontResourceExW(string path, uint flags, IntPtr reserved) { Adds++; return AddResult; }
    public static bool RemoveFontResourceExW(string path, uint flags, IntPtr reserved) { Removes++; return true; }
    public static IntPtr SendMessageTimeoutW(IntPtr hwnd, uint msg, IntPtr wp, IntPtr lp, uint flags, uint timeout, out UIntPtr result) { Notifications++; result = UIntPtr.Zero; return new IntPtr(1); }
}
'@
        $savedWindir = $env:WINDIR
    }
    AfterAll { $env:WINDIR = $savedWindir }
    BeforeEach {
        $env:WINDIR = Join-Path $TestDrive 'Windows'
        $global = $true
        $version = '2.3.0'
        $dir = Join-Path $TestDrive $version
        $script:original = Join-Path (Join-Path $env:WINDIR 'Fonts') 'seguiemj.ttf'
        $script:target = Join-Path (Join-Path $env:WINDIR 'Fonts') "Segoe.UI.Emoji.with.Twemoji.Flags.scoop-$version.ttf"
        $script:source = Join-Path $dir 'Segoe.UI.Emoji.with.Twemoji.Flags.ttf'
        $script:files = @{}; $script:files[$script:original] = 'windows'; $script:files[$script:source] = 'release'
        $script:mapping = 'seguiemj.ttf'
        $script:registryFailure = $false; $script:partialRegistryFailure = $false; $script:locked = $false
        $script:readFailure = $false; $script:copiesFail = $false; $script:changedMapping = $false
        [ScoopFlagEmojiNativeV2]::AddResult = 1
        [ScoopFlagEmojiNativeV2]::Adds = 0; [ScoopFlagEmojiNativeV2]::Removes = 0; [ScoopFlagEmojiNativeV2]::Notifications = 0
        Mock is_admin { $true }
        Mock Test-Path { $script:files.ContainsKey(@($LiteralPath)[0]) }
        Mock Get-FileHash {
            if (-not $script:files.ContainsKey(@($LiteralPath)[0])) { throw 'Missing modeled file' }
            [pscustomobject]@{ Hash = $script:files[@($LiteralPath)[0]] }
        }
        Mock Get-ItemPropertyValue {
            if ($Path -ne 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts' -or $Name -ne 'Segoe UI Emoji (TrueType)') { throw 'Unexpected registry path' }
            if ($script:readFailure) { throw 'Registry unreadable' }
            if ($script:changedMapping -and [ScoopFlagEmojiNativeV2]::Adds -gt 0) { $script:mapping = 'third-party.ttf' }
            $script:mapping
        }
        Mock Set-ItemProperty {
            if ($script:registryFailure) { throw 'Registry write failed' }
            $script:mapping = $Value
            if ($script:partialRegistryFailure -and $Value -ne 'seguiemj.ttf') { throw 'Write succeeded but reported failure' }
        }
        Mock Copy-Item {
            if ($Destination -eq $script:original) { throw 'Original font mutation attempted' }
            if ($script:copiesFail) { throw 'Copy failed' }
            $script:files[$Destination] = $script:files[@($LiteralPath)[0]]
        }
        Mock Remove-Item {
            if ($LiteralPath -eq $script:original) { throw 'Original font deletion attempted' }
            if ($script:locked) { throw 'Font locked' }
            $script:files.Remove(@($LiteralPath)[0])
        }
        Mock Write-Warning {}
    }
    It 'rejects per-user installs and removals before any mutation' {
        $global = $false
        { & $install } | Should -Throw '*elevated*'
        { & $uninstall } | Should -Throw '*global*'
        Should -Invoke Copy-Item -Times 0 -Exactly
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
    }
    It 'requires administrator privileges for both hooks' {
        Mock is_admin { $false }
        { & $install } | Should -Throw '*Administrator*'
        { & $uninstall } | Should -Throw '*Administrator*'
    }
    It 'installs a separate font and notifies without touching the Windows original' {
        & $install
        $script:mapping | Should -Be 'Segoe.UI.Emoji.with.Twemoji.Flags.scoop-2.3.0.ttf'
        $script:files[$script:original] | Should -Be 'windows'
        $script:files[$script:target] | Should -Be 'release'
        [ScoopFlagEmojiNativeV2]::Adds | Should -Be 1
        [ScoopFlagEmojiNativeV2]::Notifications | Should -Be 1
    }
    It 'rejects missing original or release font' {
        $script:files.Remove($script:original)
        { & $install } | Should -Throw '*Missing original*'
        $script:files[$script:original] = 'windows'; $script:files.Remove($script:source)
        { & $install } | Should -Throw '*Missing release*'
    }
    It 'rejects unknown active replacements including a similar Scoop filename' {
        $script:mapping = 'Segoe.UI.Emoji.with.Twemoji.Flags.scoop-1.0.0.ttf'
        { & $install } | Should -Throw '*Unknown*'
        { & $uninstall } | Should -Throw '*Another font*'
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
        Should -Invoke Remove-Item -Times 0 -Exactly
    }
    It 'rejects a different existing target or missing active file' {
        $script:files[$script:target] = 'unknown'
        { & $install } | Should -Throw '*differs*'
        { & $uninstall } | Should -Throw '*ownership*'
        $script:files.Remove($script:target)
        $script:mapping = 'Segoe.UI.Emoji.with.Twemoji.Flags.scoop-2.3.0.ttf'
        { & $install } | Should -Throw '*missing*'
    }
    It 'supports repeated installation without adding another GDI reference' {
        & $install; & $install
        [ScoopFlagEmojiNativeV2]::Adds | Should -Be 1
        Should -Invoke Copy-Item -Times 1 -Exactly
    }
    It 'leaves the original mapping on copy or GDI failure' {
        $script:copiesFail = $true
        { & $install } | Should -Throw '*Copy failed*'
        $script:copiesFail = $false
        [ScoopFlagEmojiNativeV2]::AddResult = 0
        { & $install } | Should -Throw '*registration failed*'
        $script:mapping | Should -Be 'seguiemj.ttf'
        $script:files.ContainsKey($script:target) | Should -BeFalse
    }
    It 'unloads and deletes only its new font after a registry failure' {
        $script:registryFailure = $true
        { & $install } | Should -Throw '*Registry write failed*'
        [ScoopFlagEmojiNativeV2]::Removes | Should -Be 1
        $script:files.ContainsKey($script:target) | Should -BeFalse
        $script:files[$script:original] | Should -Be 'windows'
    }
    It 'restores a write that reported failure after changing the mapping' {
        $script:partialRegistryFailure = $true
        { & $install } | Should -Throw '*reported failure*'
        $script:mapping | Should -Be 'seguiemj.ttf'
        $script:files.ContainsKey($script:target) | Should -BeFalse
    }
    It 'preserves a concurrent third-party mapping' {
        $script:changedMapping = $true
        { & $install } | Should -Throw '*changed during*'
        $script:mapping | Should -Be 'third-party.ttf'
        Should -Invoke Set-ItemProperty -Times 0 -Exactly
    }
    It 'uses old directory version during an upgrade and supports repeated removal' {
        & $install
        $version = '9.9.9' # Scoop update-scoped version must never drive old uninstall.
        & $uninstall; & $uninstall
        $script:mapping | Should -Be 'seguiemj.ttf'
        $script:files.ContainsKey($script:target) | Should -BeFalse
        $script:files[$script:original] | Should -Be 'windows'
    }
    It 'preserves the active file if restoring the registry fails' {
        & $install
        $script:registryFailure = $true
        { & $uninstall } | Should -Throw '*Registry write failed*'
        $script:files.ContainsKey($script:target) | Should -BeTrue
        Should -Invoke Remove-Item -Times 0 -Exactly
    }
    It 'warns about locked leftovers after restoring the original mapping' {
        & $install
        $script:locked = $true
        & $uninstall
        $script:mapping | Should -Be 'seguiemj.ttf'
        $script:files.ContainsKey($script:target) | Should -BeTrue
        Should -Invoke Write-Warning -ParameterFilter { $Message -like '*locked*' } -Times 1 -Exactly
    }
    It 'fails closed when the registry is unreadable' {
        $script:readFailure = $true
        { & $install } | Should -Throw '*unreadable*'
        { & $uninstall } | Should -Throw '*unreadable*'
        Should -Invoke Remove-Item -Times 0 -Exactly
    }
}
