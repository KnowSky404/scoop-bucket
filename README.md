# KnowSky Scoop Bucket

[![CI](https://github.com/KnowSky404/scoop-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/KnowSky404/scoop-bucket/actions/workflows/ci.yml) [![MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A personal [Scoop](https://scoop.sh) bucket for Windows tools, fonts, and utilities. Manifests pin upstream assets by SHA256 and upstream release updates are reviewed through pull requests, never auto-merged.

[English](#install) · [简体中文](docs/README.zh-CN.md)

## Install

In a **normal PowerShell window**, add this Bucket:

~~~powershell
scoop bucket add knowsky https://github.com/KnowSky404/scoop-bucket
scoop bucket list
scoop info knowsky/flag-emojis-for-windows
~~~

### Available manifests

| Package | Upstream | Mode |
| --- | --- | --- |
| [flag-emojis-for-windows](bucket/flag-emojis-for-windows.json) | [Chasmical/flag-emojis-for-windows](https://github.com/Chasmical/flag-emojis-for-windows) | Global (administrator only) |

The font modifies the HKLM Segoe UI Emoji mapping. It must **not** be installed as a normal Scoop per-user package, and it refuses unknown third-party font replacements. See the [Chinese manual](docs/README.zh-CN.md) and [troubleshooting](docs/TROUBLESHOOTING.md) before proceeding.

Open **PowerShell as Administrator** to install:

~~~powershell
scoop install -g knowsky/flag-emojis-for-windows
~~~

Restart Windows afterward. To update or uninstall from the elevated shell:

~~~powershell
scoop update
scoop update -g flag-emojis-for-windows
# Or uninstall and restore the original mapping:
scoop uninstall -g flag-emojis-for-windows
~~~

After removing installed packages, remove the Bucket with: scoop bucket rm knowsky.

## Maintaining the bucket

- [CI](.github/workflows/ci.yml): Scoop manifest checks, safety invariants, release checksum validation. Never modifies system fonts.
- [Update workflow](.github/workflows/autoupdate.yml): checks upstream daily and opens **draft PRs** for review, without pushing directly to main.
- The GitHub repository must permit Actions to create pull requests; workflow-created PRs using GITHUB_TOKEN do not normally trigger further PR workflows. Dispatch CI for the update branch manually.
- [Contributing guide](docs/CONTRIBUTING.md) · [Agent instructions](AGENTS.md)

**Testing limitation:** The actual installation, upgrade, and uninstall on Windows still require isolated-machine validation. Do not assume static CI validates Windows font registration.

## License and attribution

This repository's source and documentation are [MIT](LICENSE). Upstream programs have separate terms. The font derives in part from Microsoft's Segoe UI Emoji assets, so the repository license does not grant permission to redistribute the compiled font. This Bucket links to the official upstream release rather than mirroring binaries.
