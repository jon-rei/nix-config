{
  description = "NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          (pkgs.writeShellScriptBin "agenix" ''
            exec ${inputs.agenix.packages.x86_64-linux.default}/bin/agenix -i "$HOME/.config/age/keys.txt" "$@"
          '')
          age
          nixos-anywhere
          nixos-rebuild
          nixfmt-tree # nix formatter: treefmt
          nh # nicer nixos-rebuild: nh os switch
          just # task runner: just deploy drogon
          nixos-rebuild-ng # drop-in replacement with --no-reexec fix
        ];
      };

      nixosConfigurations = import ./modules/machines/nixos { inherit inputs nixpkgs; };
    };
}
