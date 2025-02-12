{...}: {
  imports = [
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/refs/tags/v1.11.0.tar.gz"}/module.nix"
    ./disk-config.nix
  ];
}
