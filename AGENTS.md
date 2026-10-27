# Instructions for Codex and other coding agents

- This repository is a Scoop Bucket, not an application.
- Follow the live Scoop schema and official BucketTemplate rather than outdated examples.
- Scoop updates run the **old uninstaller before the new installer**. In uninstall hooks, determine the old package version from its version directory, not the update-scoped version variable.
- Never overwrite or delete the Windows original seguiemj.ttf. Reject unknown active font replacements.
- Never execute actual system-font mutation scripts, elevation, or restarts on a developer machine without explicit approval.
- CI may validate manifests, hashes and script structure, but must not modify Windows system fonts.
- Scheduled updates must create human-reviewed PRs, not direct pushes or auto-merge.
- Keep English README and Chinese install, update, removal manuals in sync.
- Do not claim global font installation or rollback are proven until verified on isolated Windows.
