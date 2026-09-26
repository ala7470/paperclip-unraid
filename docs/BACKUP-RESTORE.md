# Backup and Restore

All persistent Paperclip state lives in **one directory**: `/mnt/user/appdata/paperclip/` (container path `/paperclip`). The container itself is disposable.

## What is in appdata

| Content | Purpose |
|---|---|
| Embedded PostgreSQL data (`~/.paperclip/instances/default/db` under the home) | Application database - companies, users, agents, tasks, approvals, activity log |
| Secrets key | Local secrets key file |
| Uploaded assets | File uploads |
| Agent workspaces | Local agent workspace data |

There is no external database container in the default deployment. If you later switch to an external `DATABASE_URL`, back up that database separately (see [UPSTREAM.md](UPSTREAM.md)).

## Backup

### Standard appdata backup (recommended)

Paperclip is compatible with the normal Unraid appdata backup tooling:

- **Appdata Backup/Restore v2:** `/mnt/user/appdata/paperclip` is a standard appdata path, so it is covered by the usual appdata backup settings. Verify the paperclip directory is included after installation.
- **Manual / plugin-based:** anything that copies `/mnt/user/appdata/paperclip/` (rsync, tar, USB) works.

**Consistency note:** the embedded PostgreSQL is a live database. For a guaranteed-consistent backup, stop the container first:

```sh
# Docker -> Paperclip -> Stop, then:
cd /mnt/user/appdata
tar czf paperclip-backup-$(date +%F).tar.gz paperclip/
# then start the container again
```

While the container is stopped, the on-disk state is consistent and safe to copy.

## Restore

1. Restore `/mnt/user/appdata/paperclip/` from the backup (overwrite the existing directory, or into a fresh install).
2. Create the container from `unraid/paperclip.xml` (re-import if needed) with the **same** `BETTER_AUTH_SECRET` you used originally.
3. Start the container. The embedded database is opened from the restored data directory and the board shows the previous state.

**Important:** `BETTER_AUTH_SECRET` signs sessions. If the original secret is lost, logins will fail - you will need to create a new secret and re-login (the database itself is unaffected).

## Disaster recovery scenario

The design goal is that this exact sequence always works:

1. Paperclip container is deleted (or the Unraid disk it ran on fails and the array rebuilds).
2. The official image `ghcr.io/paperclipai/paperclip:<version>` is still pullable.
3. The `/mnt/user/appdata/paperclip/` backup is restored.
4. The Unraid template is re-imported.
5. The container is recreated with the same environment (`BETTER_AUTH_SECRET`!).
6. Paperclip starts successfully.
7. Existing application state (users, companies, agents, tasks) is restored.

## External database variant

If you configured Paperclip with an external PostgreSQL via `DATABASE_URL`:

- Back up the database with `pg_dump` from the database container, e.g. `pg_dump -U paperclip paperclip > backup.sql`.
- Restore with `pg_restore` / `psql -f`.
- Also keep `/mnt/user/appdata/paperclip/` backed up (uploads, workspaces, secrets key remain there).
- Document the external database container's name, credentials location (never in this repo), network, and port in your own notes.