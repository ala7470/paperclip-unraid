# Installation on Unraid

This guide deploys the **official** Paperclip container (`ghcr.io/paperclipai/paperclip`) via the Unraid Docker Manager. No wrapper image, no manual `docker run`.

## 0. Publish the template (first time only)

The template's `Icon` URL points at `raw.githubusercontent.com/CHANGE-ME/paperclip-unraid/...`. Before distributing:

1. Create the GitHub repository `paperclip-unraid`.
2. Replace `CHANGE-ME` in `unraid/paperclip.xml` with your GitHub username/org.
3. Commit and push, then verify the icon URL resolves:
   `curl -I https://raw.githubusercontent.com/<you>/paperclip-unraid/main/unraid/paperclip-icon.png`

## 1. Prepare

- **Port:** 3100/tcp must be free. Check in Unraid Settings -> Docker or with `ss -ltn | grep :3100`.
- **Secret:** generate the required auth secret:
  ```sh
  openssl rand -hex 32
  ```
  Keep it somewhere safe. Changing it later invalidates all logged-in sessions.
- **Public URL:** the LAN URL you will use to open the board, e.g. `http://192.168.1.50:3100` (use the Unraid server's IP).

## 2. Import the template

Option A - via Community Applications (if the repo is registered):
- Community Applications -> Applications -> New Applications -> add the template repo URL -> install **Paperclip**.

Option B - manual import:
1. Download `unraid/paperclip.xml`.
2. Unraid -> Docker -> **Add Container**.
3. Click the *Import Docker XML* link (bottom-left of the Add Container page) and upload the file.
4. The form fills with all values. Fill the required fields:
   - `BETTER_AUTH_SECRET` - the secret from step 1.
   - `PAPERCLIP_PUBLIC_URL` - e.g. `http://192.168.1.50:3100`.
5. Save. Unraid pulls `ghcr.io/paperclipai/paperclip:2026.916.1` and starts the container with restart policy `unless-stopped`.

First startup creates `/mnt/user/appdata/paperclip/` contents: the embedded PostgreSQL database, the secrets key, upload storage, and agent workspaces.

## 3. Verify

- **WebUI button:** Docker -> Paperclip -> the globe/WebUI icon opens the board at `http://<server-ip>:3100/`.
- **Login:** create the first user account in the board. (`authenticated` deployment mode is the default; the first user becomes the admin.)
- **Health:** `curl http://<server-ip>:3100/api/health` should return a 200 JSON response.
- **Logs:** Docker -> Paperclip -> Logs should show the server listening on 0.0.0.0:3100 with no errors.
- **Persistence:** the appdata directory should now contain the Paperclip home tree:
  ```sh
  ls /mnt/user/appdata/paperclip/
  ```

## 4. Enable agent adapters (optional)

Docker -> Paperclip -> Edit:

- Add `OPENAI_API_KEY` and/or `ANTHROPIC_API_KEY` for the corresponding agent adapters.
- The image also pre-installs the `claude`, `codex`, `opencode`, and `gemini` CLIs so the `*_local` adapters can run in-container; set the matching API keys to use them.
- Save; Unraid recreates the container automatically (appdata is untouched).

## 5. Access from other networks

- **LAN:** default settings (`exposure=private`) allow access from the local network.
- **Extra hostnames** (Tailscale, domain aliases): set `PAPERCLIP_ALLOWED_HOSTNAMES` to comma-separated hostnames.
- **Internet-facing:** set `PAPERCLIP_DEPLOYMENT_EXPOSURE=public` **only behind TLS termination** (reverse proxy / Tailscale Funnel / WireGuard). Do not expose the board directly on the open internet.

## Unraid settings reference

| Setting | Value | Why |
|---|---|---|
| Container name | `paperclip` | Default from template |
| Image | `ghcr.io/paperclipai/paperclip:2026.916.1` | Last validated stable release |
| Network | `bridge` | Standard Unraid bridge |
| Host port | `3100` (tcp) | Board UI + API |
| Appdata | `/mnt/user/appdata/paperclip` -> `/paperclip` | All persistent data (DB, uploads, workspaces, secrets) |
| `BETTER_AUTH_SECRET` | required | Session signing secret |
| `PAPERCLIP_DEPLOYMENT_MODE` | `authenticated` | Login required |
| `PAPERCLIP_DEPLOYMENT_EXPOSURE` | `private` | LAN only |
| `PAPERCLIP_PUBLIC_URL` | your LAN URL | Base URL for the board |
| `USER_UID` / `USER_GID` | *(leave unset)* | **Do not set** - the container must run as the image's default user. Forcing the Unraid 99/100 uid crash-loops the container on first boot (`EACCES` on native-library setup). See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Privileged | no | Not needed |
| Restart | unless-stopped | Unraid default |

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Updating

See [UPDATE.md](UPDATE.md).