#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$path = Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json'
$m = Get-Content $path -Raw | ConvertFrom-Json
$raw = & gh api repos/Chasmical/flag-emojis-for-windows/releases/latest
if ($LASTEXITCODE -ne 0) { throw 'Unable to read upstream release.' }
$release = $raw | ConvertFrom-Json
if ($release.draft -or $release.prerelease -or $release.tag_name -notmatch '^v(\d+\.\d+\.\d+)$') { throw 'Unexpected upstream tag.' }
$newVersion = $Matches[1]
if ([version]$newVersion -lt [version]$m.version) { throw 'Upstream version decreased.' }
if ($newVersion -eq $m.version) {
    if ($env:GITHUB_OUTPUT) { Add-Content $env:GITHUB_OUTPUT 'changed=false' }
    return
}
$assets = @($release.assets | Where-Object { $_.name -eq 'Segoe.UI.Emoji.with.Twemoji.Flags.zip' })
if ($assets.Count -ne 1) { throw 'Missing or ambiguous ZIP release artifact.' }
$asset = $assets[0]
$url = "https://github.com/Chasmical/flag-emojis-for-windows/releases/download/v$newVersion/Segoe.UI.Emoji.with.Twemoji.Flags.zip"
if ($asset.browser_download_url -ne $url -or $asset.digest -notmatch '^sha256:([a-fA-F0-9]{64})$') { throw 'Unexpected artifact URL or missing SHA256 digest.' }
$sha = $Matches[1].ToLowerInvariant()
$tmp = Join-Path $env:RUNNER_TEMP 'release.zip'
try {
    Invoke-WebRequest -Uri $url -OutFile $tmp
    if ((Get-FileHash $tmp -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sha) { throw 'Release archive digest mismatch.' }
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
}
$m.version = $newVersion
$m.url = $url
$m.hash = $sha
[IO.File]::WriteAllText($path, (($m | ConvertTo-Json -Depth 30) + "\u0060n"), [Text.UTF8Encoding]::new($false))
if ($env:GITHUB_OUTPUT) {
    Add-Content $env:GITHUB_OUTPUT 'changed=true'
    Add-Content $env:GITHUB_OUTPUT "version=$newVersion"
}

