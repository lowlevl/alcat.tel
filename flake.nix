{
  description = "An experimentation on old Telecommunication standards.";

  inputs = {nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";};
  outputs = {nixpkgs, ...}: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
