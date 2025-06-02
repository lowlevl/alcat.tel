# - common/services: common services on all machines
{...}: let
  sources = import ../../sources.nix;
in {
  networking.firewall.enable = true;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;

    banner = ''
      ${sources.banner}

      [!!] This realm is the property of `alcat.tel`.
    '';

    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
