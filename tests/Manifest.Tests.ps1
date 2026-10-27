Describe 'Flag Emoji manifest safety checks' {
    BeforeAll {
        $manifest = Get-Content (Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json') -Raw | ConvertFrom-Json
    }
    It 'pins a SHA256 digest' { $manifest.hash | Should -Match '^[0-9a-f]{64}$' }
    It 'pins a versioned upstream release' { $manifest.url | Should -Match "/releases/download/v$([regex]::Escape($manifest.version))/" }
    It 'requires a global install' { ($manifest.pre_install -join ' ') | Should -Match '\$global' }
    It 'preserves the original Segoe UI Emoji font' {
        ($manifest.installer.script -join ' ') | Should -Match 'seguiemj\.ttf'
        ($manifest.uninstaller.script -join ' ') | Should -Match 'seguiemj\.ttf'
    }
    It 'reads old version from the Scoop app path' {
        ($manifest.uninstaller.script -join ' ') | Should -Match 'Split-Path -Path \$dir -Leaf'
    }
}

