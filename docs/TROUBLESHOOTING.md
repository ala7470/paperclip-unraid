# Troubleshooting

General Unraid debugging: Docker -> Paperclip -> **Logs**, and `docker inspect paperclip` for the effective configuration. Health endpoint: `http://<server-ip>:3100/api/health`.

## The WebUI button opens an empty page / login loop

- **`PAPERCLIP_PUBLIC_URL` mismatch.** The board validates the request's Host against the configured public URL and `PAPERCLIP_ALLOWED_HOSTNAMES`. If you open the board via a different host than configured (e.g. a hostname you did not add), Paperclip will reject the request. Fix: set `PAPERCLIP_PUBLIC_URL` to the URL you actually use, and add extra hostnames to `PAPERCLIP_ALLOWED_HOSTNAMES` if needed. Restart after saving.
- **Wrong port.** The container listens on 3100. Check the host port mapping in Docker -> Paperclip -> Edit -> Ports.

## Container starts and immediately restarts

- Check Logs for the first error.
- **Missing `BETTER_AUTH_SECRET`:** the server refuses to start without it. The template marks it required - if you imported an older template, add it via Edit.
- **Port conflict:** another container already uses host port 3100. Change the host port (container port stays 3100) and update `PAPERCLIP_PUBLIC_URL` to match.

## 403 / forbidden from the board

- **Hostname not allowed** (see first item).
- **Deployment mode:** if `PAPERCLIP_DEPLOYMENT_MODE=local_trusted`, the server binds to loopback inside the container only - it is unreachable from the LAN. This is the *only* case where you must use `authenticated` mode for Unraid. The template defaults to `authenticated` for exactly this reason.

## After an update, the board does not start

- **Database migration failure.** Check Logs for migration errors. Compare the release notes for the new version with your old one.
- **`BETTER_AUTH_SECRET` was changed** (accidentally edited) - sessions are invalid, but the server still starts; you can log in fresh. This is not a startup failure.
- **Roll back** the image tag to the previous version (see [UPDATE.md](UPDATE.md)) and check the container starts, then investigate the new version's release notes.

## Container crash-loops with `EACCES` on a `symlink` (e.g. `libcrypto.so.1.1`)

**Cause:** the container is running under a user ID that does not own files inside the image. This happens if `USER_UID`/`USER_GID` are set to Unraid's `99`/`100` while the app starts up: on first boot it tries to create native-library symlinks (e.g. `libcrypto.so.1.1`) inside image-owned directories and fails with `EACCES`.

**Fix:** remove `USER_UID` and `USER_GID` from the container entirely and let it run as the image's built-in default user. The persistent `/mnt/user/appdata/paperclip` volume is unaffected - Docker mounts are writable by the container user regardless of the host-side numeric ownership of that folder (Unraid ownership is cosmetic for containers). The current template does not set either variable; the validation script rejects them if a future edit re-introduces them.

If you already have appdata files created under a forced uid while the container was crash-looping, wipe that folder before the clean first start (fresh install only - never if you have real data; see [BACKUP-RESTORE.md](BACKUP-RESTORE.md)):

```sh
# fresh install only
rm -rf /mnt/user/appdata/paperclip/*
```

## Permission / ownership errors on appdata files

The image runs as its built-in default user. Do **not** set `PUID`/`PGID` (the image does not read them) and do **not** force `USER_UID`/`USER_GID` to `99`/`100` (see the `EACCES` entry above - that crash is the result). The host-side numeric owner of `/mnt/user/appdata/paperclip/` is cosmetic for container workloads and does not need to match `99`/`100`.

## Local adapter CLIs fail inside the container

The image pre-installs the `claude`, `codex`, `opencode`, and `gemini` CLIs for the `*_local` adapters. Failures are usually missing API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.) or network egress blocking. Check the agent run output in the board and the container Logs.

## Checking effective configuration

```sh
# Env vars actually in use
docker inspect --format='{{json .Config.Env}}' paperclip | python3 -m json.tool

# Volume mapping
docker inspect --format='{{json .Mounts}}' paperclip | python3 -m json.tool

# Port mapping
docker inspect --format='{{json .NetworkSettings.Ports}}' paperclip
```

## It works in Docker but not after a reboot

Paperclip uses `unless-stopped`, so it should start with the array. If it does not:
- Verify the container was not manually `docker stop`-ed and left with a `no` restart policy.
- Check Logs for a startup error at array boot (e.g. appdata not yet mounted - the embedded DB needs the volume mounted before start; if you use a custom startup order, make sure the array is up first).

## Health check

```sh
curl -s http://<server-ip>:3100/api/health
```

Expected: HTTP 200 with a JSON status body. If you get a connection refused, the server is not up (check Logs). If you get a 404 or redirect, check `PAPERCLIP_PUBLIC_URL` / hostname settings.