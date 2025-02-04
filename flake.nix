{
  description = ''Some fun with classic "Télécommunication" infrastructure.'';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }@input: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    nixosConfigurations = {
      # --

      # The installer configuration.
      installer = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit input; };
        system = "x86_64-linux";

        modules = [
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")

          ./modules/common.nix
          ./modules/remote.nix

          ./configurations/installer.nix
        ];
      };

      # The hermes's server configuration.
      hermes = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit input; };
        system = "x86_64-linux";

        modules = [
          ./modules/common.nix
          ./modules/remote.nix

          ./configurations/hermes.nix
        ];
      };

      # --
    };
  };
}
