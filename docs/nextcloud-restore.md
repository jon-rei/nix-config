# Restoring Nextcloud from backup

What's actually backed up (see `modules/services/nextcloud.nix` and `modules/services/backup.nix`):

- **Files/data**: `/var/lib/nextcloud` (config, apps, user data)
- **Database**: nightly `pg_dump` of the `nextcloud` Postgres database, written to
  `/var/backup/postgresql/nextcloud.sql.gz` at 03:00, *before* the restic run picks it up
- **Destination**: Hetzner Storage Box via restic, repository `sftp://<storagebox-user>@<storagebox-user>.your-storagebox.de/./backups/<hostname>`
- **Schedule**: daily, retention `7 daily / 4 weekly / 3 monthly`

All commands below run **on the Nextcloud host** (over SSH) **as root** (`sudo -i` or prefix with `sudo`), since both the restic password secret and the backed-up paths are root/service-user owned.

## 1. Find the snapshot to restore

```bash
restic-storagebox snapshots
```

This wrapper already has the repository URL and password file baked in — no need to pass `--repo`/`--password-file` manually. Note the snapshot ID you want (or use `latest`).

## 2. Stop Nextcloud so nothing writes during the restore

```bash
systemctl stop phpfpm-nextcloud nginx caddy
```

## 3. Restore the files

To restore everything to its original location:

```bash
restic-storagebox restore latest --target /
```

To restore only a subset (e.g. you only need one user's files back, not the whole instance):

```bash
restic-storagebox restore latest --target / --include /var/lib/nextcloud/data/<username>/files
```

Fix ownership afterwards if restic ran as root and paths ended up root-owned instead of `nextcloud`:

```bash
chown -R nextcloud:nextcloud /var/lib/nextcloud
```

## 4. Restore the database

The restore in step 3 already brought back `/var/backup/postgresql/nextcloud.sql.gz` (it's one of the backed-up paths). Load it into Postgres:

```bash
sudo -u postgres dropdb nextcloud
sudo -u postgres createdb -O nextcloud nextcloud
zcat /var/backup/postgresql/nextcloud.sql.gz | sudo -u postgres psql nextcloud
```

If you're restoring onto a **freshly provisioned host** rather than recovering the existing one, `nixos-rebuild switch` first (so the `nextcloud` Postgres role/db and `/var/lib/nextcloud` skeleton exist per `modules/services/nextcloud.nix`), then run steps 1–4 against it.

## 5. Bring Nextcloud back up and reconcile

```bash
systemctl start phpfpm-nextcloud nginx caddy
sudo -u nextcloud nextcloud-occ maintenance:mode --off
sudo -u nextcloud nextcloud-occ maintenance:repair --include-expensive
sudo -u nextcloud nextcloud-occ files:scan --all
```

`files:scan --all` re-syncs Nextcloud's file cache with whatever's actually on disk now — needed since the file restore happened outside of Nextcloud's own APIs.

## 6. Verify

- Log in via the web UI and confirm files/calendar/contacts look right
- `sudo -u nextcloud nextcloud-occ status` should report no errors
- Check `/var/log/nextcloud/nextcloud.log` (or the admin overview page) for anything unexpected
