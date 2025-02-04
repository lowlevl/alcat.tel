{ lib
, ...
}: {
  networking.hostName = "installer";

  boot.loader.timeout = lib.mkForce 1;
  services.getty.autologinUser = lib.mkForce null;
}
