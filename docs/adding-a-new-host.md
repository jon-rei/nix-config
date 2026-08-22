# Adding a new host

## 1. Create the NixOS configuration

Create `modules/machines/nixos/<hostname>/` with three files. The host is auto-discovered by `flake.nix` — no manual registration needed.

**`configuration.nix`** — the host's actual config, importing the other two:

```nix
{ config, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix") # or the appropriate hardware profile
    ./disko.nix
    ./secrets.nix
  ];

  # ... rest of the host config
}
```

**`disko.nix`** — the disk partition layout. This has to exist *before* provisioning in step 3, since `nixos-anywhere` needs the full flake output (partition layout included) to know how to partition the rescue-booted disk. See `modules/machines/nixos/drogon/disko.nix` for a working single-disk example.

**`secrets.nix`** — an empty stub for now:

```nix
{ ... }:
{ }
```

(populated with the host's actual `age.secrets.*` entries in step 4, once its SSH host key is known)

## 2. Add required secrets

Add any secrets the new host's config references to `secrets/secrets.nix`, then create them:

```bash
agenix -e secrets/<name>.age
```

## 3. Provision the machine

Create the VM (or bare-metal host) and boot it into rescue mode, then install from your own machine:

```bash
nixos-anywhere --flake .#<hostname> --build-on-remote root@<ip>
```

## 4. Trust the new host's SSH key

After first boot, get the host's SSH pubkey:

```bash
ssh-keyscan <ip> | grep ed25519
```

Add it to `secrets/secrets.nix` (so agenix can encrypt secrets for this host), then re-encrypt existing secrets if needed:

```bash
agenix -e secrets/<name>.age
```

## 5. Register with the Storage Box (if the host uses `backup.enable`)

restic backups authenticate to the Hetzner Storage Box via SSH host key — it only trusts keys it's seen before:

```bash
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh -p23 <storagebox-user>@<storagebox-user>.your-storagebox.de install-ssh-key
```

## 6. Deploy

```bash
just deploy <hostname>
```
