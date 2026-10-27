Describe 'Verified upstream release' {
    BeforeAll { . (Join-Path $PSScriptRoot '../scripts/Update-Helpers.ps1') }
    BeforeEach {
        $script:sha = 'a' * 64
        $script:release = [pscustomobject]@{
            tag_name = 'v2.4.0'; draft = $false; prerelease = $false
            assets = @([pscustomobject]@{ name = 'Segoe.UI.Emoji.with.Twemoji.Flags.zip'; browser_download_url = 'https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v2.4.0/Segoe.UI.Emoji.with.Twemoji.Flags.zip'; digest = "sha256:$script:sha" })
        }
        Mock Invoke-UpdateGh { $script:release | ConvertTo-Json -Depth 10 }
        Mock Invoke-WebRequest {}
        Mock Get-FileHash { [pscustomobject]@{ Hash = $script:sha } }
        Mock Remove-Item {}
    }
    It 'verifies stable release, exact URL and independent SHA256' {
        $r = Get-VerifiedFlagRelease
        $r.Version | Should -Be '2.4.0'
        $r.Hash | Should -Be $script:sha
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        Should -Invoke Remove-Item -Times 1 -Exactly
    }
    It 'rejects draft, prerelease, and malformed release versions' {
        $script:release.draft = $true
        { Get-VerifiedFlagRelease } | Should -Throw '*unstable*'
        $script:release.draft = $false; $script:release.prerelease = $true
        { Get-VerifiedFlagRelease } | Should -Throw '*unstable*'
        $script:release.prerelease = $false; $script:release.tag_name = 'v02.4.0'
        { Get-VerifiedFlagRelease } | Should -Throw '*tag*'
    }
    It 'rejects missing or duplicate release assets' {
        $asset = $script:release.assets[0]
        $script:release.assets = @()
        { Get-VerifiedFlagRelease } | Should -Throw '*artifact*'
        $script:release.assets = @($asset, $asset)
        { Get-VerifiedFlagRelease } | Should -Throw '*ambiguous*'
    }
    It 'rejects missing digest and an unofficial URL' {
        $script:release.assets[0].digest = $null
        { Get-VerifiedFlagRelease } | Should -Throw '*digest*'
        $script:release.assets[0].digest = "sha256:$script:sha"
        $script:release.assets[0].browser_download_url = 'https://example.com/font.zip'
        { Get-VerifiedFlagRelease } | Should -Throw '*URL*'
    }
    It 'rejects mismatched downloaded bytes and cleans the temporary file' {
        Mock Get-FileHash { [pscustomobject]@{ Hash = 'b' * 64 } }
        { Get-VerifiedFlagRelease } | Should -Throw '*digest mismatch*'
        Should -Invoke Remove-Item -Times 1 -Exactly
    }
    It 'propagates network failures and cleans partial downloads' {
        Mock Invoke-WebRequest { throw 'Network request failed' }
        { Get-VerifiedFlagRelease } | Should -Throw '*Network*'
        Should -Invoke Remove-Item -Times 1 -Exactly
    }
    It 'propagates API rate limits before download or mutation' {
        Mock Invoke-UpdateGh { throw 'API rate limit exceeded' }
        { Get-VerifiedFlagRelease } | Should -Throw '*rate limit*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
    }
    It 'checks the requested pinned tag' {
        { Get-VerifiedFlagRelease -Tag 'v2.3.0' } | Should -Throw '*tag mismatch*'
    }
}

Describe 'Update decision without repository mutation' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '../scripts/Update-Helpers.ps1')
        $updater = Join-Path $PSScriptRoot '../scripts/update-manifest.ps1'
        $realManifest = Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json'
    }
    BeforeEach {
        $fixture = Join-Path $TestDrive 'manifest.json'
        Copy-Item $realManifest $fixture
        $script:initial = Get-Content $fixture -Raw | ConvertFrom-Json
        $script:r = [pscustomobject]@{ Version = $script:initial.version; Url = $script:initial.url; Hash = $script:initial.hash }
        $savedOutput = $env:GITHUB_OUTPUT
        $env:GITHUB_OUTPUT = Join-Path $TestDrive 'output.txt'
        Remove-Item $env:GITHUB_OUTPUT -ErrorAction SilentlyContinue
        Mock Get-VerifiedFlagRelease { $script:r }
        Mock Publish-FlagUpdate {}
    }
    AfterEach { $env:GITHUB_OUTPUT = $savedOutput }
    It 'keeps identical manifest bytes and creates no PR on repeated no-op runs' {
        $before = [IO.File]::ReadAllText($fixture)
        Update-FlagManifest -ManifestPath $fixture -CreatePullRequest
        Update-FlagManifest -ManifestPath $fixture -CreatePullRequest
        [IO.File]::ReadAllText($fixture) | Should -BeExactly $before
        Get-Content $env:GITHUB_OUTPUT | Should -Contain 'changed=false'
        Should -Invoke Publish-FlagUpdate -Times 0 -Exactly
    }
    It 'updates version, URL and hash together for a newer stable release' {
        $script:r.Version = '9.0.0'; $script:r.Url = 'https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v9.0.0/Segoe.UI.Emoji.with.Twemoji.Flags.zip'; $script:r.Hash = 'c' * 64
        Update-FlagManifest -ManifestPath $fixture
        $m = Get-Content $fixture -Raw | ConvertFrom-Json
        $m.version | Should -Be '9.0.0'; $m.url | Should -Be $script:r.Url; $m.hash | Should -Be $script:r.Hash
        Get-Content $env:GITHUB_OUTPUT | Should -Contain 'changed=true'
    }
    It 'connects a newer verified release to Draft PR publication only from main' {
        $savedRef = $env:GITHUB_REF; $savedRepo = $env:GITHUB_REPOSITORY
        try {
            $script:r.Version = '9.0.0'; $script:r.Url = 'https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v9.0.0/Segoe.UI.Emoji.with.Twemoji.Flags.zip'; $script:r.Hash = 'c' * 64
            $env:GITHUB_REF = 'refs/heads/feature'; $env:GITHUB_REPOSITORY = 'example/bucket'
            { Update-FlagManifest -ManifestPath $fixture -CreatePullRequest } | Should -Throw '*start from main*'
            $env:GITHUB_REF = 'refs/heads/main'
            Update-FlagManifest -ManifestPath $fixture -CreatePullRequest
            Should -Invoke Publish-FlagUpdate -ParameterFilter { $OldVersion -eq $script:initial.version -and $NewVersion -eq '9.0.0' -and $Hash -eq ('c' * 64) } -Times 1 -Exactly
        } finally { $env:GITHUB_REF = $savedRef; $env:GITHUB_REPOSITORY = $savedRepo }
    }
    It 'rejects a downgrade without writing the fixture' {
        $script:r.Version = '0.1.0'
        { Update-FlagManifest -ManifestPath $fixture } | Should -Throw '*decreased*'
        (Get-Content $fixture -Raw | ConvertFrom-Json).version | Should -Be $script:initial.version
    }
    It 'detects a manifest URL or digest inconsistent with its version' {
        $script:r.Url = 'https://example.com/wrong.zip'
        { Update-FlagManifest -ManifestPath $fixture -CheckOnly } | Should -Throw '*does not match*'
        { Update-FlagManifest -ManifestPath $fixture } | Should -Throw '*differs*'
    }
}

Describe 'Draft PR publication and interrupted run recovery' {
    BeforeAll { . (Join-Path $PSScriptRoot '../scripts/Update-Helpers.ps1') }
    BeforeEach {
        $script:prs = '[]'; $script:remote = ''; $script:prFailure = $false; $script:conflict = $false
        $script:manifestText = Get-Content (Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json') -Raw
        $obj = $script:manifestText | ConvertFrom-Json
        $obj.version = '2.4.0'; $obj.hash = 'a' * 64
        $obj.url = 'https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v2.4.0/Segoe.UI.Emoji.with.Twemoji.Flags.zip'
        $script:manifestText = $obj | ConvertTo-Json -Depth 30
        Mock Get-Content { $script:manifestText }
        Mock Invoke-UpdateGh {
            if ($Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'list') { return $script:prs }
            if ($Arguments[0] -eq 'pr' -and $Arguments[1] -eq 'create') {
                if ($script:prFailure) { throw 'PR permission denied' }
                return 'https://github.com/example/bucket/pull/1'
            }
            throw 'Unexpected gh call'
        }
        Mock Invoke-UpdateGit {
            if ($Arguments[0] -eq 'ls-remote') { return $script:remote }
            if ($Arguments[0] -eq 'show') { return $script:manifestText }
            if ($Arguments[0] -eq 'diff') { if ($script:conflict) { return 'README.md' }; return 'bucket/flag-emojis-for-windows.json' }
            return ''
        }
    }
    It 'pushes a dedicated branch and creates a Draft PR with a reviewable body' {
        Publish-FlagUpdate -Repository example/bucket -OldVersion 2.3.0 -NewVersion 2.4.0 -Hash ('a' * 64)
        Should -Invoke Invoke-UpdateGit -ParameterFilter { $Arguments[0] -eq 'push' -and $Arguments[2] -eq 'HEAD:refs/heads/automation/flag-emojis-2.4.0' } -Times 1 -Exactly
        Should -Invoke Invoke-UpdateGh -ParameterFilter { $Arguments[1] -eq 'create' -and $Arguments -contains '--draft' -and $Arguments -contains '--body-file' } -Times 1 -Exactly
        Should -Invoke Invoke-UpdateGit -ParameterFilter { $Arguments -contains '--force' -or $Arguments -contains 'HEAD:refs/heads/main' } -Times 0 -Exactly
    }
    It 'does not duplicate open, closed or merged PRs even with a leftover branch' -TestCases @(@{State='OPEN'}, @{State='CLOSED'}, @{State='MERGED'}) {
        param($State)
        $script:prs = "[{`"number`":1,`"state`":`"$State`",`"url`":`"https://example.com/pr/1`"}]"
        $script:remote = 'existing'
        Publish-FlagUpdate -Repository example/bucket -OldVersion 2.3.0 -NewVersion 2.4.0 -Hash ('a' * 64)
        Should -Invoke Invoke-UpdateGh -ParameterFilter { $Arguments[1] -eq 'create' } -Times 0 -Exactly
        Should -Invoke Invoke-UpdateGit -Times 0 -Exactly
    }
    It 'recovers a pushed matching branch after a failed PR request without a second push' {
        $script:remote = 'existing'
        Publish-FlagUpdate -Repository example/bucket -OldVersion 2.3.0 -NewVersion 2.4.0 -Hash ('a' * 64)
        Should -Invoke Invoke-UpdateGit -ParameterFilter { $Arguments[0] -eq 'push' } -Times 0 -Exactly
        Should -Invoke Invoke-UpdateGh -ParameterFilter { $Arguments[1] -eq 'create' } -Times 1 -Exactly
    }
    It 'rejects a conflicting existing branch without overwriting it' {
        $script:remote = 'existing'; $script:conflict = $true
        { Publish-FlagUpdate -Repository example/bucket -OldVersion 2.3.0 -NewVersion 2.4.0 -Hash ('a' * 64) } | Should -Throw '*differs*'
        Should -Invoke Invoke-UpdateGit -ParameterFilter { $Arguments[0] -eq 'push' } -Times 0 -Exactly
    }
    It 'fails visibly on PR permission denial so a rerun can recover the pushed branch' {
        $script:prFailure = $true
        { Publish-FlagUpdate -Repository example/bucket -OldVersion 2.3.0 -NewVersion 2.4.0 -Hash ('a' * 64) } | Should -Throw '*permission denied*'
    }
}
