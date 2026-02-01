{
  description = "Nix crimes for Alcat.tel telephony network";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    naersk,
    treefmt-nix,
    sops-nix,
    disko,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {pkgs, ...}: {
        formatter = (treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper;
        packages = self.overlays.default {} pkgs;

        devShells.default = pkgs.callPackage ./shell.nix {};
      };

      flake = {
        # Include all our packages into `nixpkgs`
        overlays.default = final: prev: let
          naersk' = prev.callPackage naersk {};
        in rec {
          dahdi-linux = prev.linuxPackages.callPackage ./pkgs/dahdi-linux {};
          dahdi-tools = prev.callPackage ./pkgs/dahdi-tools {inherit dahdi-linux;};
          yate = prev.callPackage ./pkgs/yate {inherit dahdi-linux;};
          ascripts = prev.callPackage ./pkgs/ascripts {inherit yate;};
          atelco = prev.callPackage ./pkgs/atelco {inherit naersk';};
        };

        nixosModules = {
          common = import ./mods/common;
          dahdi = import ./mods/dahdi;
          yate = import ./mods/yate.nix;
          atelco = import ./mods/atelco.nix;
          sipdect = import ./mods/sipdect;
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
            self.nixosModules.atelco
            self.nixosModules.sipdect

            sops-nix.nixosModules.default
            disko.nixosModules.default

            ./confs/zero
          ];
        };
      };
    };
}
