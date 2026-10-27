#Requires -Version 7.0
# Scoop's checkhashes.ps1 reports mismatches without a failing exit code.
# Reuse its manifest resolution; fail CI on any pinned SHA256 mismatch.
[CmdletBinding()]
param([string]$BucketPath = (Join-Path $PSScriptRoot '../bucket'))
$ErrorActionPreference = 'Stop'
if (-not $env:SCOOP_HOME) { throw 'SCOOP_HOME must point to the checked-out Scoop source.' }
. (Join-Path $env:SCOOP_HOME 'lib/manifest.ps1')
$seen = @{}
foreach ($file in Get-ChildItem -LiteralPath $BucketPath -Filter '*.json') {
    if ($file.BaseName -eq 'flag-emojis-for-windows') {
        & (Join-Path $PSScriptRoot 'update-manifest.ps1') -ManifestPath $file.FullName -CheckOnly
        continue
    }
    $m = Get-Content $file.FullName -Raw | ConvertFrom-Json
    if ($m.version -eq 'nightly') { throw "Unpinned nightly manifest: $($file.Name)" }
    $architectures = if ($m.architecture) { @($m.architecture.PSObject.Properties.Name) } else { @('64bit') }
    foreach ($arch in $architectures) {
        $urls = @(url $m $arch); $hashes = @(hash $m $arch)
        if ($urls.Count -eq 0 -or $urls.Count -ne $hashes.Count) { throw "Missing or unmatched URL/hash: $($file.Name) $arch" }
        for ($i = 0; $i -lt $urls.Count; $i++) {
            $expected = $hashes[$i] -replace '^sha256:', ''
            if ($expected -notmatch '^[a-fA-F0-9]{64}$') { throw "Require pinned SHA256: $($file.Name)" }
            $uri = ($urls[$i] -split '#', 2)[0]
            $key = "$uri|$expected"
            if ($seen.ContainsKey($key)) { continue }
            $tmp = Join-Path ([IO.Path]::GetTempPath()) ("scoop-hash-$([guid]::NewGuid())")
            try {
                Invoke-WebRequest -Uri $uri -OutFile $tmp -ErrorAction Stop
                if ((Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash -ine $expected) { throw "SHA256 mismatch: $($file.Name) $arch $uri" }
            } finally { Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue }
            $seen[$key] = $true
            Write-Host "Verified $($file.Name) $arch SHA256."
        }
    }
}
