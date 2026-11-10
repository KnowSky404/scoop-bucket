# Contributing

This is a Scoop bucket for fonts, tools and utilities. Follow the live [Scoop schema](https://github.com/ScoopInstaller/Scoop/blob/master/schema.json) and [BucketTemplate](https://github.com/ScoopInstaller/BucketTemplate).

1. Add `bucket/<lowercase-package-name>.json` with official versioned downloads and pinned SHA256. Do not check in binaries or run remote installers.
2. Ordinary packages use normal Scoop hooks; the Segoe UI Emoji lifecycle is specific to `flag-emojis-for-windows`. Include verified `checkver` and `autoupdate` declarations where possible.
3. Document elevation, persistent data, system changes and recovery. Keep README and the Chinese manual synchronized.
4. Run `./bin/test.ps1` in PowerShell 5.1 and 7, with `SCOOP_HOME` pointing to Scoop's source and BuildHelpers >= 2.0.1 / Pester >= 5.2.0 installed. Run `./scripts/check-hashes.ps1` in PowerShell 7. These checks never install fonts. Run lifecycle tests in a fresh process; they compile a native API double with no P/Invoke.
5. Work in a dedicated Git worktree and branch based on current `main`. Submit a PR with the release URL, checks and risks. Wait for Codex review on the current head, address applicable findings, and request another review if the head changes. `main` requires a PR and resolved review conversations, but no status checks. GitHub does not enforce the configured up-to-date branch option without a required status check, so check the base before merging. Once review and validation are complete, rebase-merge manually, delete the remote and local branches, and remove the worktree. There is no required second reviewer, no ruleset bypass, and no automatic merge.
6. System-font lifecycle changes require isolated Windows acceptance before claiming installation/rollback is proven. Never use a developer machine or CI runner for real font mutation, elevation or restarts without explicit authorization.

## Manually checking upstream releases

The manually dispatched updater currently manages only Flag Emojis. Run `gh workflow run autoupdate.yml --repo KnowSky404/scoop-bucket --ref main` to check for an update. It verifies a stable canonical `vX.Y.Z` tag, the exact official ZIP URL, GitHub's release asset SHA256 and an independently downloaded SHA256. Missing digests fail closed; there is no silent checksum fallback. API, network and permission errors fail the run with diagnostics; resolve the cause and rerun, rather than inventing a release or disabling validation.

No new version means no commit or PR. New versions use `automation/flag-emojis-<version>` and a Draft PR, never a push to `main`. Existing open, closed or merged PRs prevent duplicates. A branch left by a failed PR request is reused only if its complete manifest and changed-file list match the verified proposal; it is never force-pushed. A closed PR needs maintainer action; a merged PR with an old local manifest means refresh `main`. The concurrency group serializes manual runs. Creating a new update PR is allowed only from `main`; feature-branch dispatches can verify the current release and the temporary permission probe.

When dispatched, CI discovers every manifest, checks the live Scoop schema and hook syntax, and downloads each pinned artifact (all declared architectures). The special font release also checks its URL against its release tag and the upstream digest. Scoop's `checkhashes.ps1` only reports mismatches, so the small CI hash verifier uses Scoop's URL/hash resolution and throws on failure. Adding an ordinary second manifest needs no CI redesign. Future update support can share these workflows/helpers or Scoop's official checkver tooling; do not copy the font policy onto ordinary packages or add a workflow per package. Dependabot checks Actions weekly and creates PRs; no second bot manages Actions versions and no auto-merge job exists.

## Reviewing PRs and running CI

Default repository token permissions are read-only; only the updater job requests `contents: write` and `pull-requests: write`. The repository permission named “Allow GitHub Actions to create and approve pull requests” enables creation; this updater never submits approvals or merges.

PRs and pushes do not trigger CI. To validate a PR branch on GitHub, dispatch read-only CI and inspect the run:

```powershell
$branch = 'automation/flag-emojis-2.4.0' # Replace with the PR branch.
gh workflow run ci.yml --repo KnowSky404/scoop-bucket --ref $branch
gh run list --repo KnowSky404/scoop-bucket --workflow ci.yml --branch $branch --json databaseId,headSha,status,conclusion
```

Check that the run's `headSha` equals the PR's latest commit and that both Scoop test jobs and `checksum` passed. Alternatively, run the local PowerShell tests and checksum validation described above. Inspect the diff and isolated Windows evidence before marking a Draft ready. Wait for Codex review on the current head, address applicable findings, and rebase-merge manually only after review and validation finish. Delete the merged branch.

To test actual workflow-token PR creation without fake manifest versions, explicitly dispatch `autoupdate.yml` with `verify_pr_creation=true`. It creates a uniquely named `automation/permission-test-<run>-<attempt>` branch containing only a test marker, verifies a Draft PR authored by the Actions bot, then closes it and deletes the branch in `finally`. It never merges. If cancellation/network failure interrupts cleanup, inspect the run and close/delete only that uniquely identified test PR/branch. Testing a feature-branch revision against `main` can include that revision's commits in the temporary PR; its only additional commit is the marker. Production manifests are never changed for this probe.
