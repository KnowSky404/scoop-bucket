#Requires -Version 7.0
# Explicit dispatch-only integration test. Does not edit a manifest or main.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Update-Helpers.ps1')
if (-not $env:GITHUB_RUN_ID -or $env:GITHUB_EVENT_NAME -ne 'workflow_dispatch') { throw 'This probe requires an explicit workflow_dispatch.' }
$branch = "automation/permission-test-$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT"
$repo = $env:GITHUB_REPOSITORY
$prNumber = $null
try {
    $null = Invoke-UpdateGit @('config', 'user.name', 'github-actions[bot]')
    $null = Invoke-UpdateGit @('config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com')
    $null = Invoke-UpdateGit @('switch', '-c', $branch)
    Set-Content -LiteralPath 'PERMISSION-TEST.txt' -Value "Temporary GITHUB_TOKEN PR permission probe. Run $env:GITHUB_RUN_ID. No font or manifest changes."
    $null = Invoke-UpdateGit @('add', '--', 'PERMISSION-TEST.txt')
    $null = Invoke-UpdateGit @('commit', '-m', 'test: temporary Actions PR permission probe')
    $null = Invoke-UpdateGit @('push', 'origin', "HEAD:refs/heads/$branch")
    $url = Invoke-UpdateGh @('pr', 'create', '--repo', $repo, '--base', 'main', '--head', $branch, '--draft', '--title', '[TEMPORARY TEST] GITHUB_TOKEN Draft PR permission', '--body', "Permission verification only; close without merging. Run $env:GITHUB_RUN_ID. No manifest changes.")
    $pr = Invoke-UpdateGh @('pr', 'view', $url, '--repo', $repo, '--json', 'number,isDraft,state,headRefName,author,url') | ConvertFrom-Json
    $prNumber = $pr.number
    if (-not $pr.isDraft -or $pr.state -ne 'OPEN' -or $pr.headRefName -ne $branch -or $pr.author.login -notmatch 'github-actions') { throw 'Unexpected test PR state or author.' }
    Write-Host "Verified workflow GITHUB_TOKEN created Draft PR: $($pr.url) by $($pr.author.login)"
    if ($env:GITHUB_STEP_SUMMARY) { Add-Content $env:GITHUB_STEP_SUMMARY "Verified real GITHUB_TOKEN Draft PR creation: $($pr.url). Test PR closed and branch cleanup attempted in finally." }
} finally {
    # Recover even when creation succeeded but its response/readback was interrupted.
    if (-not $prNumber) {
        $prData = Invoke-UpdateGh @('pr', 'list', '--repo', $repo, '--head', $branch, '--state', 'open', '--json', 'number') | ConvertFrom-Json
        $prs = @($prData | Where-Object { $_.number })
        if ($prs.Count -gt 0) { $prNumber = $prs[0].number }
    }
    if ($prNumber) { $null = Invoke-UpdateGh @('pr', 'close', "$prNumber", '--repo', $repo) }
    $remote = Invoke-UpdateGit @('ls-remote', '--heads', 'origin', "refs/heads/$branch")
    if ($remote) { $null = Invoke-UpdateGit @('push', 'origin', '--delete', $branch) }
    Write-Host "Temporary PR and branch cleaned: $branch"
}
