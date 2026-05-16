# nix-config

Personal NixOS infrastructure, managed as a public flake on GitHub.

## Hosts

| Hostname | Hardware | Services |
|---|---|---|
| `drogon` | Hetzner Cloud VM | Caddy, OpenCloud, Collabora |

## Repo structure

```
flake.nix
modules/
  services/
    backup.nix                   # restic backup — enable per machine with backup.enable = true
    caddy.nix                    # Caddy + static websites
    opencloud.nix                # OpenCloud + Caddy vhost + Collabora CSP
    collabora.nix                # Collabora Online + Caddy vhost + font mounts
  machines/
    nixos/
      _common/
        default.nix              # shared baseline: nix settings, SSH, timezone
      drogon/
        configuration.nix        # host entry point — imports services, sets backup paths
        disko.nix                # disk layout — used by nixos-anywhere to partition
        secrets.nix              # sops secret declarations
        secrets.yaml             # sops-encrypted values — committed to git, safe to push
  users/
    jonas/
      default.nix                # user account, SSH keys, trusted-users
      dots.nix                   # home-manager dotfiles — applies to every machine
secrets/
  secrets.nix                    # maps age pubkeys to secret files (agenix)
  drogon/
    opencloud-env.age      # encrypted secrets committed to git
    restic-password.age
```

## Dev shell

```bash
nix develop
# provides: agenix, age, nixos-anywhere
```

If you haven't set up direnv yet:
```bash
sudo pacman -S direnv
# add to ~/.config/fish/config.fish:
#   direnv hook fish | source
direnv allow   # run once inside the repo
```

After that the shell activates automatically when you cd into the repo.

## Secrets (agenix)

Secrets are `.age` files encrypted with age keys and committed to the repo. The host decrypts at boot using its SSH host key.

### First-time setup

**Step 1 — generate your personal age key** (once, back this up):
```bash
age-keygen -o ~/.config/age/keys.txt
# prints: public key: age1xxxxx...
# → add to secrets/secrets.nix under desktop
```

**Step 2 — install machine** (see below). After first boot:

```bash
# Get SSH host pubkey
ssh-keyscan <ip> | grep ed25519
# → add to secrets/secrets.nix under drogon

# Create secrets (opens $EDITOR) — run from secrets/
cd secrets
agenix -e drogon/opencloud-env.age  # IDM_ADMIN_PASSWORD=<password>
agenix -e drogon/restic-password.age      # <random password, never change>

# Add SSH host key to your storage box authorized_keys (for restic backups)
cat /etc/ssh/ssh_host_ed25519_key.pub | ssh -p23 u00000@u00000.your-storagebox.de install-ssh-key

# Redeploy
just deploy drogon
```

### Editing a secret

```bash
cd secrets && agenix -e drogon/opencloud-env.age
```

## Installing drogon

1. Create the VM in the Hetzner console (any Linux OS)
2. Enable the **rescue system** in the Hetzner console and reboot
3. From your machine:

```bash
nix develop
nixos-anywhere --flake .#drogon --build-on-remote root@<ip>
```

nixos-anywhere SSHes in, boots into a kexec RAM environment, runs disko to wipe and partition the disk, installs NixOS, and reboots.

## Rebuilding drogon

```bash
# Remotely from your machine
nixos-rebuild switch --flake .#drogon --target-host jonas@<ip> --use-remote-sudo

# Or directly on the host
sudo nixos-rebuild switch --flake github:YOUR_GITHUB_USER/nix-config#drogon
```

## Adding a new host

1. Create `modules/machines/nixos/<hostname>/configuration.nix` and `secrets.nix`
2. Add it to `flake.nix` under `nixosConfigurations`
3. Leave `sops.defaultSopsFile` commented out for the first deploy
4. Install, then complete the secrets setup (see above)
