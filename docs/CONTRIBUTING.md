# Contributing

This is a standard Scoop bucket. Validate manifests against the current [Scoop schema](https://github.com/ScoopInstaller/Scoop/blob/master/schema.json) and the [official bucket template](https://github.com/ScoopInstaller/BucketTemplate).

1. Add one file under bucket/<package>.json, using the upstream versioned download and pinned SHA256.
2. Include checkver and autoupdate where verified.
3. Document elevated installation, persistent data, system changes, and a safe uninstall path.
4. Never execute unpinned remote installer scripts or copy copyrighted font binaries into this repository.
5. Run Scoop's Pester tests and checksum checks; CI must not register system fonts.
6. Submit a PR with changelog, release URL, verification details, and risks. System-level hooks require an isolated Windows test.

Automated upstream updates are draft PRs requiring maintainer review.
