{ lib
, ...
}:
let
  keys = import ./keys.nix { };
in
{
  users.users.technician.openssh.authorizedKeys.keys = keys;

  services.openssh = {
    enable = true;

    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = false;
    };

    openFirewall = true;
  };
}
