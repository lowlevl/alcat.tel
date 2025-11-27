{
  description = "Nix crimes for Alcat.tel telephony network";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    sops-nix,
    disko,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        packages = self.overlays.default {} pkgs;
      };

      flake = {
        # Include all our packages into `nixpkgs`
        overlays.default = final: prev: rec {
          dahdi-linux = prev.linuxPackages.callPackage ./pkgs/dahdi-linux {};
          dahdi-tools = prev.callPackage ./pkgs/dahdi-tools {inherit dahdi-linux;};
          yate = prev.callPackage ./pkgs/yate {inherit dahdi-linux;};
          rmanager = prev.callPackage ./pkgs/rmanager.nix {};
          atel = prev.callPackage ./pkgs/atel {inherit yate;};
        };

        nixosModules = {
          common = import ./mods/common;
          dahdi = import ./mods/dahdi;
          yate = import ./mods/yate.nix;
        };

        nixosConfigurations."zero" = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            overlays = [self.overlays.default];
          };

          specialArgs = {
            atel = {
              realm = "alcat.tel's telephony network";
              banner = ''
                  ┓        ┓
                ┏┓┃┏┏┓╋ ╋┏┓┃
                ┗┻┗┗┗┻┗•┗┗ ┗
              '';
            };
          };

          modules = [
            self.nixosModules.common
            self.nixosModules.dahdi
            self.nixosModules.yate

            sops-nix.nixosModules.default
            disko.nixosModules.default

            ./confs/zero
          ];
        };
      };
    };
}
