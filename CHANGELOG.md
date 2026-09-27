# Changelog

All notable changes to the **Unraid integration** (not the upstream Paperclip application). Format follows [Keep a Changelog](https://keepachangelog.com/). Upstream application changes live in the [Paperclip release notes](https://github.com/paperclipai/paperclip/releases).

## [Unreleased]

### Fixed
- Removed `USER_UID`/`USER_GID` from the template and from the validator's required-variable list. Forcing the Unraid user IDs (99/100) crashes the container: the app hits `EACCES` on a native-library `symlink` (e.g. `libcrypto.so.1.1`) inside an image-owned path because it runs as a uid that doesn't own those files. The container now runs as the image's default user; the persistent `/mnt/user/appdata/paperclip` volume is unaffected.
- The validator now **rejects** `USER_UID`/`USER_GID` (as well as `PUID`/`PGID`/`UMASK`) so a future edit can't re-introduce the crash.
- `docs/TROUBLESHOOTING.md` gained an entry for the `EACCES symlink` crash.

## [0.1.0] - 2026-09-26

### Added
- Initial Unraid Docker Manager template (`unraid/paperclip.xml`) for the official `ghcr.io/paperclipai/paperclip` image, pinned to stable release `2026.916.1`.
- Icon (`unraid/paperclip-icon.png`, 512x512, from official UI assets, MIT).
- Documentation: INSTALL, UPDATE, BACKUP-RESTORE, TROUBLESHOOTING, UPSTREAM.
- Template validation script and CI workflow (`scripts/validate_template.sh`, `.github/workflows/validate-template.yml`).
- Weekly upstream release watch workflow (`.github/workflows/upstream-check.yml`).

### Notes
- Deployment validated against Paperclip source at v2026.916.1: image tag scheme (CalVer, no `v` prefix), port 3100, required `BETTER_AUTH_SECRET`, deployment mode/exposure variables, single `/paperclip` data volume (embedded PostgreSQL + uploads + workspaces), runtime `USER_UID`/`USER_GID` remap, `/api/health` endpoint. No wrapper image required.
- The `Icon` URL in the template contains a `CHANGE-ME` placeholder and must be set to the published raw-GitHub URL of this repository before the template is distributed (see `docs/INSTALL.md`, step 0).