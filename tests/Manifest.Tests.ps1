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


Describe 'PowerShell syntax (never invokes hooks)' {
    It 'parses lifecycle hooks for all manifests' {
        Get-ChildItem (Join-Path $PSScriptRoot '../bucket') -Filter '*.json' | ForEach-Object {
            $m = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $scopes = @($m) + @($m.architecture.PSObject.Properties | ForEach-Object { $_.Value })
            foreach ($scope in $scopes) {
                foreach ($name in @('pre_install','post_install','pre_uninstall','post_uninstall','installer','uninstaller')) {
                    $code = $scope.$name
                    if ($name -in @('installer','uninstaller')) { $code = $code.script }
                    if ($code) {
                        $parseErrors = $null
                        $null = [System.Management.Automation.Language.Parser]::ParseInput(($code -join "`n"), [ref]$null, [ref]$parseErrors)
                        $parseErrors | Should -BeNullOrEmpty -Because "$($_.Name) $name"
                    }
                }
            }
        }
    }
}
