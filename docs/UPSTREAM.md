# Upstream Paperclip

This repository is an **integration layer**, not a fork. It treats Paperclip as an external dependency delivered through its published container image.

## Official upstream

- **Project:** <https://github.com/paperclipai/paperclip>
- **Image registry:** `ghcr.io/paperclipai/paperclip`
- **License:** MIT (Copyright (c) 2025 Paperclip AI)

## Current pinned version

**`2026.916.1`** (released 2026-09-21) - the last validated stable release as of this template version.

## Release and tag tracking

Upstream release flow (verified from `.github/workflows/docker.yml`):

1. Stable releases are tagged `vYYYY.MMDD.N` on GitHub (with a `v` prefix in git).
2. The Docker workflow pushes **CalVer image tags without the `v` prefix** to GHCR - e.g. `v2026.916.1` -> image tag `2026.916.1`.
3. The `latest` image tag moves **only** on stable releases.
4. Beta lane tags (`beta/v*`) publish to `:beta`; nightly lane tags publish to `:nightly`; every build also publishes `:sha-<commit>`, and `:canary` tracks npm dist-tags.

So the mapping for this template is:

| Upstream release tag | Image tag | Action here |
|---|---|---|
| `v2026.916.1` (stable) | `2026.916.1`, `latest` | Review -> bump the template `Branch` pin |
| `beta/v2026.924.0` | `2026.924.0`, `beta` | No action unless the user opts into beta |
| nightly / canary | `nightly`, `canary`, `sha-*` | No action |

**Release tracking method:**

- GitHub Releases: <https://github.com/paperclipai/paperclip/releases>
- GHCR tags (live check): `docker manifest inspect ghcr.io/paperclipai/paperclip:<tag>`
- This repository's `.github/workflows/upstream-check.yml` runs weekly, lists the newest upstream release, and opens a reminder issue when the pinned version is older than the latest stable - **it never changes the template automatically.**

## Release review checklist

When a new stable release appears, before bumping the pinned version verify:

- [ ] Release notes: breaking changes, migration notes, auth changes.
- [ ] Docker image: new/changed env vars (compare `docker inspect` of the new image against the current pin).
- [ ] Port changes (default 3100).
- [ ] Storage changes (default `/paperclip` data dir).
- [ ] Database migrations and embedded-PostgreSQL behavior.
- [ ] Startup command / entrypoint changes.
- [ ] Authentication changes (deployment mode, `BETTER_AUTH_SECRET`).
- [ ] Networking / health endpoint (`/api/health`).

If no template changes are required, bump `Branch` to the new tag, update `README.md`, add a `CHANGELOG.md` entry, and document compatibility. If changes are required, update `unraid/paperclip.xml` accordingly.

## Known compatibility considerations

- **No `stable` tag exists** - use `latest` (stable-only) or a pinned CalVer tag.
- **Image tags have no `v` prefix** - the git tag is `v2026.916.1` but the image tag is `2026.916.1`. Do not use the `v`-prefixed tag in the template.
- **`BETTER_AUTH_SECRET` is required** at startup since the server will not boot without it.
- **`local_trusted` deployment mode is loopback-only** - unusable behind the Unraid WebUI button; keep `authenticated`.
- **UID remap uses `USER_UID`/`USER_GID`**, not `PUID`/`PGID`.
- **No Docker `HEALTHCHECK` is defined in the image** - use `/api/health` via a health-check plugin or the curl command in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
- **Single data volume** - `/paperclip` holds the embedded database, uploads, workspaces, and the secrets key. Do not split it into separate mappings.