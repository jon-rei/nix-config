# nix-config

Personal NixOS infrastructure, managed as a public flake on Codeberg.

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

## Installing a new host

1. Create the VM and boot into rescue mode
2. From your machine:
```bash
nixos-anywhere --flake .#<hostname> --build-on-remote root@<ip>
```
3. After first boot, get the SSH host pubkey and add it to `secrets/secrets.nix`:
```bash
ssh-keyscan <ip> | grep ed25519
```
4. Create the secrets for the host:
```bash
agenix -e secrets/<name>.age
```
5. Add the SSH host key to your storage box (for restic backups):
```bash
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh -p23 u00000@u00000.your-storagebox.de install-ssh-key
```
6. Redeploy:
```bash
just deploy <hostname>
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

## Adding a new host

1. Create `modules/machines/nixos/<hostname>/configuration.nix`
2. The host is auto-discovered by `flake.nix` — no manual registration needed
3. Add required secrets to `secrets/secrets.nix`
4. Install with nixos-anywhere (see above)
