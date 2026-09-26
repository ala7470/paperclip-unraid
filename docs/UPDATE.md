# Updating Paperclip

Updates use the **official upstream container image**. This repository does not build anything and does not install any updater inside the container. The container is disposable; all state lives in `/mnt/user/appdata/paperclip/`.

## Tag model

Upstream publishes on `ghcr.io/paperclipai/paperclip`:

| Tag | Meaning | Moves |
|---|---|---|
| `2026.916.1` (CalVer, **no `v` prefix**) | Specific stable release | Never - immutable |
| `latest` | Newest stable release | Only when a new stable version is published |
| `beta` | Beta channel | On beta releases |
| `nightly` | Nightly builds | On nightly lane builds |
| `sha-<40>` | Exact commit build | Never |

There is **no `stable` tag** - `latest` already tracks stable only.

**The template pins a specific stable version** (`Branch` element). This is the recommended default: updates are explicit and reproducible.

## Update procedure

1. Check upstream: see [UPSTREAM.md](UPSTREAM.md) - compare the currently pinned version with the newest stable release, read release notes, and confirm no template changes are required.
2. In the template, change `Branch` from the old version to the new one, e.g. `2026.916.1` -> `2026.924.0`. Update the pin in `README.md` and `CHANGELOG.md` too.
3. Apply to the running container:
   - **Manual:** Docker -> Paperclip -> Edit -> change the image tag -> Save. Unraid pulls the new image and recreates the container; appdata is reused.
   - **Or** set the container to track `latest`: Docker -> Paperclip -> Edit -> change the image tag to `latest` -> Save. Then use the standard Update button. **Stability trade-off:** `latest` auto-follows every stable upstream release, including any breaking changes; the pinned tag lets you review each release first.
4. Verify after the update:
   ```sh
   curl http://<server-ip>:3100/api/health
   ```
   - Open the board via the WebUI button.
   - Check Logs for migration output - Paperclip runs database migrations on startup automatically; confirm they completed without errors.
   - Verify existing data is intact (companies, agents, tasks).

## Rollback

If an update misbehaves, revert the image tag to the previous version in Docker -> Paperclip -> Edit -> Save. The previous appdata schema remains compatible as long as the new version did not complete an irreversible migration; check the release notes for migration notes before updating.

## What is NOT part of updating

- No local builds, no fork, no source sync.
- No in-container updater that modifies the application filesystem.
- No database migration performed manually - migrations are part of the container's normal startup.

## Compatibility with CA Auto Update Applications

The Community Applications *Auto Update Applications* plugin updates containers by re-pulling the configured image tag and recreating. Because this deployment uses a published image with external appdata and `unless-stopped`, it is compatible. With a pinned tag, the auto-update plugin only detects an update after you (or this repository) bump the pinned tag - which is the intended review gate. With `latest`, upstream stable releases are picked up automatically.