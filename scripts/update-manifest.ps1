#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot '../bucket/flag-emojis-for-windows.json'),
    [switch]$CheckOnly,
    [switch]$CreatePullRequest
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Update-Helpers.ps1')
Update-FlagManifest @PSBoundParameters
