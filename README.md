# KnowSky404 Scoop Bucket

[![MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A personal [Scoop](https://scoop.sh) bucket for Windows tools, fonts, and utilities. Manifests pin upstream assets by SHA256 and upstream release updates are reviewed through pull requests, never auto-merged.

[English](#install) · [简体中文](docs/README.zh-CN.md)

## Install

In a **normal PowerShell window**, add this Bucket:

~~~powershell
scoop bucket add KnowSky404 https://github.com/KnowSky404/scoop-bucket
scoop bucket list
scoop info KnowSky404/flag-emojis-for-windows
~~~

If you previously added this bucket as `knowsky`, keep that entry and skip the `bucket add` command above: installed packages retain their original bucket association for future updates. If you already removed it, restore it with `scoop bucket add knowsky https://github.com/KnowSky404/scoop-bucket`. Use `knowsky/flag-emojis-for-windows` in place of `KnowSky404/flag-emojis-for-windows`. To remove the bucket after uninstalling its packages, use `scoop bucket rm knowsky`.

### Available manifests

| Package | Upstream | Mode |
| --- | --- | --- |
| [flag-emojis-for-windows](bucket/flag-emojis-for-windows.json) | [Chasmical/flag-emojis-for-windows](https://github.com/Chasmical/flag-emojis-for-windows) | Global (administrator only) |

The font modifies the HKLM Segoe UI Emoji mapping. It must **not** be installed as a normal Scoop per-user package, and it refuses unknown third-party font replacements. See the [Chinese manual](docs/README.zh-CN.md) and [troubleshooting](docs/TROUBLESHOOTING.md) before proceeding.

Open **PowerShell as Administrator** to install:

~~~powershell
scoop install -g KnowSky404/flag-emojis-for-windows
~~~

Restart Windows afterward. In a **normal shell**, refresh Scoop and bucket manifests (this does not upgrade installed software):

~~~powershell
scoop update
~~~

In **administrator PowerShell**, upgrade or uninstall the installed global font:

~~~powershell
scoop update -g flag-emojis-for-windows
# Or uninstall and restore the original mapping:
scoop uninstall -g flag-emojis-for-windows
~~~

Restart after upgrade or removal. Scoop runs the **old uninstaller before the new installer**. A failed upgrade can leave the original Windows mapping active; Scoop does not roll back all system effects. Locked versioned files can remain for manual inspection after restart. Keep the old package directory until recovery is understood; `scoop cleanup` removes old package files, not locked copies in Windows Fonts. Windows Update may reset the mapping: inspect it before retrying or reinstalling. Never overwrite or delete Windows' original `seguiemj.ttf`.

The hooks require the original font file to exist, accept only the original mapping or the exact matching current package file, compare an existing target's content with the package source, unload their GDI resource during removal, and notify applications with a bounded timeout. They reject unknown replacements. File existence does not authenticate the Windows original: repair a suspect OS font through Windows servicing before installing this package.

After uninstalling packages, remove the bucket in a **normal shell**:

~~~powershell
scoop bucket rm KnowSky404
~~~

## Maintaining the bucket

- [CI](.github/workflows/ci.yml) runs on manual dispatch: Scoop manifest checks, safety invariants, and release checksum validation. It never modifies system fonts.
- [Update workflow](.github/workflows/autoupdate.yml) runs on manual dispatch from `main` and opens **draft PRs** for newer upstream releases, without pushing directly to main: `gh workflow run autoupdate.yml --repo KnowSky404/scoop-bucket --ref main`.
- Default Actions token permissions are read-only; only the updater job requests repository/PR writes. Actions PR creation is enabled. No PAT is stored for updating.
- PRs and pushes do not run CI automatically. For manual CI and local PowerShell checks, see the [review and validation procedure](docs/CONTRIBUTING.md#reviewing-prs-and-running-ci).
- The `main` ruleset requires PRs and resolved review conversations, and prevents force pushes and deletion. It no longer requires status checks; without one, GitHub does not enforce the configured up-to-date branch option. There is no bypass or automatic merge. Dependabot proposes Actions updates weekly.
- The updater verifies official stable tags/ZIP URLs, release digests and independent hashes. Equal versions make no commit; reruns recover matching orphan branches and avoid duplicate PRs. Only Flag Emojis has update automation today; dispatched CI discovers ordinary additional manifests automatically.
- [Contributing guide](docs/CONTRIBUTING.md) · [Agent instructions](AGENTS.md)

**Testing limitation:** The installation, upgrade, rollback, file locking, restart/display behavior and Windows Update recovery still require isolated Windows acceptance. CI uses a mocked registry/filesystem and a native API double; it never changes runner system fonts. See the [acceptance checklist](docs/TROUBLESHOOTING.md#isolated-windows-acceptance) and [delivery evidence](VERIFICATION.md).

## License and attribution

This repository's source and documentation are [MIT](LICENSE). Upstream programs have separate terms. The font derives in part from Microsoft's Segoe UI Emoji assets, so the repository license does not grant permission to redistribute the compiled font. This Bucket links to the official upstream release rather than mirroring binaries.
