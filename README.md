# nix-config

Personal NixOS infrastructure, managed as a public flake.

## Dev shell

```bash
nix develop
# provides: agenix, age, nixos-anywhere, nh, just, nixfmt-tree, nixos-rebuild-ng
```

With direnv the shell activates automatically when you `cd` into the repo:
```bash
direnv allow   # run once inside the repo
```

## Secrets (agenix)

Secrets are `.age` files encrypted with age keys and committed to the repo. Each host decrypts at boot using its SSH host key.

**Generate your personal age key** (once, back this up):
```bash
age-keygen -o ~/.config/age/keys.txt
# prints: public key: age1xxxxx...
# → add to secrets/secrets.nix under desktop
```

**Edit a secret:**
```bash
agenix -e secrets/<name>.age
```

## Deploying

```bash
# Deploy from your machine (builds locally, copies to host)
just deploy <hostname>

# Preview changes without applying
just dry <hostname>

# Or directly on the host
sudo nixos-rebuild switch --flake git+https://github.com/jon-rei/nix-config#<hostname> --refresh
```

## Docs

- [Adding a new host](docs/adding-a-new-host.md)
- [Restoring Nextcloud from backup](docs/nextcloud-restore.md)
