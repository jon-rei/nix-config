set quiet

# List available commands
default:
  just --list

# Update all flake inputs
update:
  nix develop --command nix flake update

# Deploy to a host (builds on remote)
deploy host:
  nix develop --command nixos-rebuild-ng switch --flake .#{{host}} \
    --target-host jonas@{{host}}.dinoverse.de \
    --build-host jonas@{{host}}.dinoverse.de \
    --no-reexec \
    --sudo

# Preview what would change without applying
dry host:
  nix develop --command nixos-rebuild-ng dry-activate --flake .#{{host}} \
    --target-host jonas@{{host}}.dinoverse.de \
    --build-host jonas@{{host}}.dinoverse.de \
    --no-reexec \
    --sudo

# Show package diff without applying
diff host:
  nix develop --command nh os build .#nixosConfigurations.{{host}}

# Format all nix files
fmt:
  nix develop --command nixfmt **/*.nix

# SSH into a host
ssh host:
  ssh jonas@{{host}}.dinoverse.de
