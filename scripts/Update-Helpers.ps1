# Shared by the scheduled updater and isolated Pester tests. No system-font operations.
function Invoke-UpdateGh {
    param([string[]]$Arguments)
    $output = & gh @Arguments
    if ($LASTEXITCODE -ne 0) { throw "gh failed ($LASTEXITCODE): $($Arguments -join ' '). Check network, API rate limits, and Actions PR permissions; rerun after resolving the cause." }
    $output -join "`n"
}

function Invoke-UpdateGit {
    param([string[]]$Arguments)
    $output = & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git failed ($LASTEXITCODE): $($Arguments -join ' ')" }
    $output -join "`n"
}

function Get-VerifiedFlagRelease {
    param([string]$Tag = 'latest')
    $endpoint = if ($Tag -eq 'latest') { 'latest' } else { "tags/$Tag" }
    $release = Invoke-UpdateGh @('api', "repos/Chasmical/flag-emojis-for-windows/releases/$endpoint") | ConvertFrom-Json
    if ($release.draft -or $release.prerelease -or $release.tag_name -cnotmatch '^v((?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*))$') { throw 'Unexpected upstream tag or unstable release.' }
    $newVersion = $Matches[1]
    if ($Tag -ne 'latest' -and $release.tag_name -cne $Tag) { throw 'Release tag mismatch.' }
    $assets = @($release.assets | Where-Object { $_.name -ceq 'Segoe.UI.Emoji.with.Twemoji.Flags.zip' })
    if ($assets.Count -ne 1) { throw 'Missing or ambiguous ZIP release artifact.' }
    $asset = $assets[0]
    $url = "https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v$newVersion/Segoe.UI.Emoji.with.Twemoji.Flags.zip"
    if ($asset.browser_download_url -cne $url -or $asset.digest -cnotmatch '^sha256:([a-fA-F0-9]{64})$') { throw 'Unexpected artifact URL or missing SHA256 digest.' }
    $sha = $Matches[1].ToLowerInvariant()
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("scoop-release-$([guid]::NewGuid()).zip")
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmp -ErrorAction Stop
        if ((Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sha) { throw 'Release archive digest mismatch.' }
    } finally { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }
    [pscustomobject]@{ Version = $newVersion; Url = $url; Hash = $sha; ReleaseUrl = "https://github.com/Chasmical/flag-emojis-for-windows/releases/tag/v$newVersion" }
}

function Publish-FlagUpdate {
    param([string]$Repository, [string]$OldVersion, [string]$NewVersion, [string]$Hash)
    if ($Repository -notmatch '^[\w.-]+/[\w.-]+$' -or $NewVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid repository or version.' }
    $localManifest = Get-Content -LiteralPath 'bucket/flag-emojis-for-windows.json' -Raw | ConvertFrom-Json
    $expectedUrl = "https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v$NewVersion/Segoe.UI.Emoji.with.Twemoji.Flags.zip"
    if ($localManifest.version -cne $NewVersion -or $localManifest.hash -ine $Hash -or $localManifest.url -cne $expectedUrl) { throw 'Local manifest does not match the verified update.' }
    $branch = "automation/flag-emojis-$NewVersion"
    $prData = Invoke-UpdateGh @('pr', 'list', '--repo', $Repository, '--head', $branch, '--base', 'main', '--state', 'all', '--json', 'number,state,url') | ConvertFrom-Json
    # Windows PowerShell can emit an empty JSON array as one pipeline object.
    $prs = @($prData | Where-Object { $_.number })
    if ($prs.Count -gt 0) {
        Write-Host "Existing PR for $NewVersion ($($prs[0].state)): $($prs[0].url). No duplicate; closed PRs require maintainer action, merged PRs require refreshing main."
        return
    }
    $remote = Invoke-UpdateGit @('ls-remote', '--heads', 'origin', "refs/heads/$branch")
    if ($remote) {
        # Recover a push followed by a failed PR request without overwriting any branch.
        $null = Invoke-UpdateGit @('fetch', 'origin', $branch)
        $files = Invoke-UpdateGit @('diff', '--name-only', 'origin/main', 'FETCH_HEAD')
        $remoteManifest = Invoke-UpdateGit @('show', 'FETCH_HEAD:bucket/flag-emojis-for-windows.json') | ConvertFrom-Json
        if ($files.Trim() -ne 'bucket/flag-emojis-for-windows.json' -or ($remoteManifest | ConvertTo-Json -Depth 30 -Compress) -cne ($localManifest | ConvertTo-Json -Depth 30 -Compress)) { throw "Existing branch $branch differs; inspect manually. No overwrite performed." }
    } else {
        $null = Invoke-UpdateGit @('config', 'user.name', 'github-actions[bot]')
        $null = Invoke-UpdateGit @('config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com')
        $null = Invoke-UpdateGit @('switch', '-c', $branch)
        $null = Invoke-UpdateGit @('add', '--', 'bucket/flag-emojis-for-windows.json')
        $null = Invoke-UpdateGit @('commit', '-m', "chore: update flag-emojis-for-windows to $NewVersion")
        $null = Invoke-UpdateGit @('push', 'origin', "HEAD:refs/heads/$branch")
    }
    $body = @"
Updates flag-emojis-for-windows from **$OldVersion** to **$NewVersion**.

Release: https://github.com/Chasmical/flag-emojis-for-windows/releases/tag/v$NewVersion

Verified stable release tag, exact official ZIP name/URL, release SHA256 digest, and independently downloaded ZIP SHA256: ``$Hash``.

Maintainer: inspect the diff and release, approve pending CI via **Approve workflows to run**, and verify the Windows lifecycle on an isolated machine. If no PR run appears, dispatch CI on this branch: ``gh workflow run ci.yml --ref $branch``. Confirm green checks for the current head before marking ready and merging manually. No auto-merge.
"@
    $bodyFile = Join-Path ([IO.Path]::GetTempPath()) ("scoop-pr-$([guid]::NewGuid()).md")
    try {
        [IO.File]::WriteAllText($bodyFile, $body, [Text.UTF8Encoding]::new($false))
        Invoke-UpdateGh @('pr', 'create', '--repo', $Repository, '--draft', '--base', 'main', '--head', $branch, '--title', "chore: update flag-emojis-for-windows to $NewVersion", '--body-file', $bodyFile)
    } finally { Remove-Item -LiteralPath $bodyFile -ErrorAction SilentlyContinue }
}

function Update-FlagManifest {
    [CmdletBinding()]
    param(
        [string]$ManifestPath = (Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json'),
        [switch]$CheckOnly,
        [switch]$CreatePullRequest
    )
    $ErrorActionPreference = 'Stop'
    $m = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $oldVersion = $m.version
    if ($oldVersion -notmatch '^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$') { throw 'Invalid manifest version.' }
    $release = if ($CheckOnly) { Get-VerifiedFlagRelease -Tag "v$oldVersion" } else { Get-VerifiedFlagRelease }
    if ($CheckOnly) {
        if ($m.version -cne $release.Version -or $m.url -cne $release.Url -or $m.hash -ine $release.Hash) { throw 'Manifest version, official release URL, or SHA256 does not match.' }
        Write-Host "Verified pinned v$oldVersion release URL, release digest and independent ZIP SHA256."
        return
    }
    if ([version]$release.Version -lt [version]$oldVersion) { throw 'Upstream version decreased.' }
    if ($release.Version -ceq $oldVersion) {
        if ($m.url -cne $release.Url -or $m.hash -ine $release.Hash) { throw 'Existing manifest differs from the verified release.' }
        Write-Host "No update: $oldVersion is the latest stable release; archive verified."
        if ($env:GITHUB_OUTPUT) { Add-Content $env:GITHUB_OUTPUT 'changed=false' }
        return
    }
    if ($CreatePullRequest -and $env:GITHUB_REF -ne 'refs/heads/main') { throw 'Production update PRs must start from main. Use isolated tests on feature branches.' }
    $m.version = $release.Version
    $m.url = $release.Url
    $m.hash = $release.Hash
    [IO.File]::WriteAllText($ManifestPath, (($m | ConvertTo-Json -Depth 30) + "`n"), [Text.UTF8Encoding]::new($false))
    if ($env:GITHUB_OUTPUT) {
        Add-Content $env:GITHUB_OUTPUT 'changed=true'
        Add-Content $env:GITHUB_OUTPUT "version=$($release.Version)"
    }
    if ($CreatePullRequest) {
        if (-not $env:GITHUB_REPOSITORY) { throw 'GITHUB_REPOSITORY is required.' }
        Publish-FlagUpdate -Repository $env:GITHUB_REPOSITORY -OldVersion $oldVersion -NewVersion $release.Version -Hash $release.Hash
    }
}
