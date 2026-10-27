# Repository hardening delivery evidence

Audit date: 2026-10-27. Changes are submitted on `maintenance/bucket-hardening`, not merged automatically. This report distinguishes live repository settings, proposed code, and unverified Windows behavior.

## Repository resources (API write followed by readback)

| Setting | Before | Verified after |
| --- | --- | --- |
| Visibility / default branch | Public / main | Public / main (preserved) |
| Description | Already the requested description | Preserved: A curated Scoop bucket for Windows tools, fonts, and utilities, with verified manifests and reviewed automated updates. |
| Topics | Empty | scoop-bucket, scoop, windows, powershell, package-manager, fonts, emoji, github-actions |
| Issues / Pull Requests | Enabled / enabled | Enabled / enabled |
| Wiki / Projects | Enabled / enabled | Disabled / disabled |
| Squash merge | Enabled | Enabled |
| Delete merged head branches | Disabled | Enabled |
| Auto merge | Disabled | Disabled |
| Actions availability | Enabled, all actions allowed | Preserved; proposed workflows use only SHA-pinned GitHub checkout plus explicit Gallery test dependencies |
| Default token | Read | Read |
| Allow Actions to create/approve PRs | Disabled | Enabled for PR creation; workflows never approve or merge |
| main protection | No rulesets, classic protection returned 404 | Active [ruleset 25940327](https://github.com/KnowSky404/scoop-bucket/rules/25940327), no bypass actors |

Rules: PR required with **zero** required approvals (solo maintenance remains possible), resolved review threads, up-to-date branch, no force push and no branch deletion. Required checks were read from successful [main CI](https://github.com/KnowSky404/scoop-bucket/actions/runs/40467565095), not guessed: `scoop-tests (powershell)`, `scoop-tests (pwsh)`, `checksum`, all GitHub Actions app ID 15368. Both the ruleset and effective branch rules were queried after configuration. No bot/admin bypass is configured. Repository auto-merge remains disabled.

CI has `contents: read` only. Proposed updater defaults to read-only and grants `contents: write`, `pull-requests: write` to its sole proposing job. It has no merge command, automatic approval or long-lived PAT. GitHub's repository checkbox combines create and approve capabilities; enabling it does not mean the code uses approval capability. Dependabot remains weekly, with at most three Actions PRs, no auto-merge and no duplicate dependency-update bot.

## Changes delivered

- `.github/workflows/ci.yml`: retain stable Windows PowerShell / pwsh check names and Scoop tests; install test dependencies explicitly instead of an additional third-party cache action; add timeouts; verify pinned releases and all manifests' checksums without installation.
- `.github/workflows/autoupdate.yml`: daily/manual schedule, job-scoped writes, serialized runs, recoverable Draft PR creation, optional dispatch-only token permission probe.
- `bucket/flag-emojis-for-windows.json`: tighter ownership and version validation, Scoop's admin helper on both paths, GDI unload, bounded WM_FONTCHANGE, partial-write rollback and preservation on unsafe recovery. Original font is never a copy/removal target.
- `scripts/update-manifest.ps1`, `scripts/Update-Helpers.ps1`: checked CLI errors; stable tags; exact asset URL/name/digest; independent download; combined version/URL/hash proposal; equal-version no-op; duplicate suppression and safe branch reuse; explicit Draft PR review guidance. No production version was fabricated.
- `scripts/check-hashes.ps1`: discover ordinary packages and architecture downloads using Scoop's manifest resolution, fail on missing/incorrect pinned SHA256. Scoop's official hash reporting tool does not itself fail on mismatch, so CI supplies this small enforcing wrapper.
- `scripts/test-pr-permission.ps1`: explicitly requested temporary branch/Draft PR test using the job's real `GITHUB_TOKEN`, readback and cleanup; no fake manifest change or merge.
- `bin/test.ps1`: run official tests against all manifests even for documentation-only changes.
- `tests/Manifest.Tests.ps1`, `tests/FontLifecycle.Tests.ps1`, `tests/Updater.Tests.ps1`, `tests/Hashes.Tests.ps1`: hook syntax, isolated font lifecycle, upstream failures/update decisions, PR recovery, ordinary package architecture coverage. Official schema/script-file checks are reused rather than reimplemented.
- `README.md`, `docs/README.zh-CN.md`, `docs/TROUBLESHOOTING.md`, `docs/CONTRIBUTING.md`, `AGENTS.md`, this report: synchronized commands/elevation, review/approval flow, rollback limits, cleanup, Windows Update, recovery and isolated acceptance.

## Validation and Actions evidence

- Original main CI already passed all three required checks: [40467565095](https://github.com/KnowSky404/scoop-bucket/actions/runs/40467565095). Historical push and PR runs both succeeded.
- Existing main updater manually dispatched: [40469725108](https://github.com/KnowSky404/scoop-bucket/actions/runs/40469725108), **success**, equal version 2.3.0, PR step skipped. No update branch, commit or duplicate PR was created.
- Local PowerShell 7.6.9 ran isolated tests and downloaded the actual pinned official ZIP. Upstream release asset digest and independent SHA256 both matched `d4a924fa96576a3f247834995777295a2e92ddadabc8456fef8e7e4bdd502902` for v2.3.0. The first feature-branch PowerShell 7 CI passed **50 tests**, including the live Scoop schema with no skips, and checksum verification passed. Windows PowerShell 5.1 then exposed its different empty-JSON-array pipeline behavior in four PR-publication tests (44 passed / 4 failed / 2 PS7-only tests skipped); PR results are now normalized explicitly. CI also saves compatible modules through pwsh to avoid slow legacy Gallery tooling and still executes tests in the matrix-selected shell. The corrected code passed both shells as recorded below.
- Proposed updater / real token probe: [40471051787](https://github.com/KnowSky404/scoop-bucket/actions/runs/40471051787), **success**. It verified the unchanged release and created [temporary Draft PR #3](https://github.com/KnowSky404/scoop-bucket/pull/3) as `app/github-actions`. API readback confirms CLOSED, still Draft, never merged, and its `automation/permission-test-40471051787-1` branch is absent. No production manifest changed for the probe.
- The bot-created PR produced [CI 40471086860](https://github.com/KnowSky404/scoop-bucket/actions/runs/40471086860), conclusion **action_required**, at the test head. This verifies the approval-required behavior directly; the closed test PR was not approved or merged.
- Delivery PR: [#2](https://github.com/KnowSky404/scoop-bucket/pull/2), open for maintainer review. Main is unchanged at `786175e3ad53eb7f45b8938492e886822aa03c92`.

- Corrected code CI at `18af3e64621f4edff9d64ca691d34d2b46b9d2db`: [PR run 40471665027](https://github.com/KnowSky404/scoop-bucket/actions/runs/40471665027), **success** for all three required jobs. Windows PowerShell 5.1: **48 passed, 0 failed, 2 intentionally skipped** (the standalone SHA256 checker requires PS7); PowerShell 7: **50 passed, 0 failed, 0 skipped**. The official live-schema test passed in both shells. Actual ZIP verification passed. GitHub reports PR #2 `mergeStateStatus: CLEAN`, proving the ruleset permits this solo-maintainer PR path with all checks satisfied; no merge was performed.
- Corrected updater second dispatch: [40471803352](https://github.com/KnowSky404/scoop-bucket/actions/runs/40471803352), **success**, equal stable version, independent download verified, permission probe intentionally skipped. No update commit/PR or production update branch was created. A separate manually dispatched CI run [40471798601](https://github.com/KnowSky404/scoop-bucket/actions/runs/40471798601) validates the same code via `workflow_dispatch`; use its live result rather than inferring success from the PR run.

New test value: lifecycle tests model per-user/non-admin refusals, unknown/missing/mismatched files, idempotence, GDI/copy failures, registry-write and partial-write failures, third-party changes, old-version uninstall, locked files and unreadable registry. Native methods are managed doubles without DllImport; filesystem/registry calls are mocked. Updater tests model tags, missing/duplicate assets, digest/URL mismatch, rate limits/network errors, downgrade/no-op/new-version decisions, dedicated Draft branch, duplicate open/closed/merged PRs, orphan branches, conflicting branches and PR permission failure. Ordinary package tests demonstrate automatic discovery and independent architecture hashes.

## Safety audit and release decision

Scoop source inspected at [e6aa3b366bdee8ed138c1e0f7b85192ebdd35d0f](https://github.com/ScoopInstaller/Scoop/blob/e6aa3b366bdee8ed138c1e0f7b85192ebdd35d0f/libexec/scoop-update.ps1#L348): old uninstall gets the old version directory before new installation. The hook derives its version from `$dir`, never the update-scoped `$version`. Original mapping is restored before removal; the exact owned file is hash-checked against its retained package source. Unknown active mappings are preserved by refusal. A failed new install may leave the original Windows mapping rather than the old patched version. Matching-prefix filenames alone do not establish ownership. Existing installations can still carry their previously saved Scoop hooks until reinstalled/upgraded; changing the bucket does not rewrite installed hook history.

The original `seguiemj.ttf` must exist and is never overwritten/deleted. **Existence is not provenance verification**; a suspect/missing Windows original requires supported Windows repair. System-font locks can leave a versioned copy after restoration; warnings identify it, and recovery/cleanup procedures are documented. WM_FONTCHANGE uses a timeout rather than an indefinitely blocking broadcast. External registry edits can race system operations; scripts recheck before changing/removing and preserve uncertain state, but they do not provide an OS-wide transaction or guarantee restoration after process termination/power loss.

No actual system-font installation/removal, HKLM mutation, developer-machine elevation, or restart was performed. CI is deliberately unable to prove real GDI registration, Windows locking, post-restart flag rendering, interrupted-upgrade behavior or Windows Update recovery. These are explicit [isolated Windows acceptance items](docs/TROUBLESHOOTING.md#isolated-windows-acceptance), not claimed successes. A VM/snapshot and explicit authorization are required before running them.

The repository settings can be used now. Proposed code requires maintainer review and manual merge; no automatic merge was requested or performed. The bucket is **not yet a proven production-safe global font release** until isolated Windows acceptance is recorded. Ordinary manifest maintenance and reviewed update automation are designed for public use, subject to the recorded checks.

## Official references

- [Live Scoop schema](https://github.com/ScoopInstaller/Scoop/blob/master/schema.json) and [official BucketTemplate](https://github.com/ScoopInstaller/BucketTemplate).
- [GitHub workflow triggering](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow): token-created PR opened/synchronize/reopened events may produce approval-required runs. Approve after inspection; manually dispatch CI on the exact head if needed. Token-created push events do not normally start another run.

Microsoft API references used during review: [AddFontResourceExW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-addfontresourceexw), [RemoveFontResourceExW](https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-removefontresourceexw), [SendMessageTimeoutW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw). Add/remove use identical flags, the add return value is checked, and the broadcast timeout applies per receiving window.

The final report-only commit does not change tested PowerShell, workflows or manifests. The PR checks run again on that head; consult [PR #2 checks](https://github.com/KnowSky404/scoop-bucket/pull/2/checks) for the latest status. The final delivery message records that head's actual outcome. Repository administration changes are live; proposed code remains on the feature branch pending manual review and merge.
