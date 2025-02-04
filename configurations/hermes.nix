#- The `hermes` server, handling messaging and voice data.

{ ... }: {
  imports = [
    ../modules/common.nix
    ../modules/remote.nix
  ];

  networking.hostName = "hermes";
}
