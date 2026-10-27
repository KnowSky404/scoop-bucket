Describe 'Ordinary manifest checksum verification' -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
    BeforeAll { $checker = Join-Path $PSScriptRoot '../scripts/check-hashes.ps1' }
    BeforeEach {
        $bucket = Join-Path $TestDrive 'bucket'
        New-Item -ItemType Directory -Path $bucket -Force | Out-Null
        $script:expected = 'a' * 64
        $m = @{
            version = '1.0.0'
            architecture = @{
                '64bit' = @{ url = 'https://example.com/tool-x64.zip#/tool.zip'; hash = $script:expected }
                'arm64' = @{ url = 'https://example.com/tool-arm64.zip'; hash = $script:expected }
            }
        }
        $m | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $bucket 'ordinary-tool.json')
        Mock Invoke-WebRequest {}
        Mock Get-FileHash { [pscustomobject]@{ Hash = $script:expected } }
    }
    It 'discovers a second ordinary package and checks each architecture without font hooks' {
        & $checker -BucketPath $bucket
        Should -Invoke Invoke-WebRequest -Times 2 -Exactly
        Should -Invoke Invoke-WebRequest -ParameterFilter { $Uri -eq 'https://example.com/tool-x64.zip' } -Times 1 -Exactly
    }
    It 'fails on a downloaded hash mismatch' {
        Mock Get-FileHash { [pscustomobject]@{ Hash = 'b' * 64 } }
        { & $checker -BucketPath $bucket } | Should -Throw '*SHA256 mismatch*'
    }
}
