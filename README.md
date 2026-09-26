# paperclip-unraid

Unraid integration for [Paperclip](https://github.com/paperclipai/paperclip) - a control plane for AI-agent companies.

This repository is **not a fork**. It contains only the files needed to deploy the **official Paperclip container image** as a native Unraid application:

```
Official Paperclip (github.com/paperclipai/paperclip)
        ->
Official container image (ghcr.io/paperclipai/paperclip)
        ->
This repository (XML template + icon + docs + release monitoring)
        ->
Unraid Docker Manager
```

## Contents

| Path | Purpose |
|---|---|
| `unraid/paperclip.xml` | Docker Manager template (DockerMan v2) |
| `unraid/paperclip-icon.png` | 512x512 icon, from the official UI (MIT) |
| `docs/INSTALL.md` | Installation on Unraid |
| `docs/UPDATE.md` | Update model and workflow |
| `docs/BACKUP-RESTORE.md` | Backup, restore, disaster recovery |
| `docs/TROUBLESHOOTING.md` | Diagnostics and fixes |
| `docs/UPSTREAM.md` | Upstream image/tag tracking |
| `scripts/validate_template.sh` | Template schema + safety checks (also used by CI) |
| `.github/workflows/validate-template.yml` | Runs validation on push/PR |
| `.github/workflows/upstream-check.yml` | Weekly upstream release watch |

## Official image

- **Image:** `ghcr.io/paperclipai/paperclip`
- **Pinned in template:** `2026.916.1` (last validated stable release)
- **Tag scheme:** CalVer without a `v` prefix (e.g. `2026.916.1`), plus `latest` (moves only on stable releases), `beta`, `nightly`, `sha-<40>`.
- **WebUI port:** `3100`
- **Persistent data:** single volume `/mnt/user/appdata/paperclip` -> `/paperclip` (embedded PostgreSQL, uploads, agent workspaces, secrets key)

## Quick start

1. Generate a secret: `openssl rand -hex 32`
2. Import `unraid/paperclip.xml` in Unraid (Docker -> Add Container -> Import XML)
3. Set `BETTER_AUTH_SECRET` and `PAPERCLIP_PUBLIC_URL`, then Save
4. Open the board from the Unraid WebUI button

Full instructions: [docs/INSTALL.md](docs/INSTALL.md)

## Validation status

The template was generated from, and verified against, the Paperclip source at release **v2026.916.1** (2026-09-21): Dockerfile, `docker/docker-compose.quickstart.yml`, `scripts/docker-entrypoint.sh`, `server/src/config.ts`, and live GHCR manifest checks. See [docs/UPSTREAM.md](docs/UPSTREAM.md) for the release-checklist used to re-validate future versions.

## License

Template, docs, and scripts: MIT. The icon is derived from the official Paperclip UI assets (MIT, Copyright (c) 2025 Paperclip AI).