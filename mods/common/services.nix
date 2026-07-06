# - common/services: common services on all machines
{
  atel,
  pkgs,
  ...
}: {
  networking.firewall.enable = true;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;

    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;

      Banner = let
        file = pkgs.writeText "banner.txt" ''
          ${atel.banner}

          [!!] This realm is the property of `alcat.tel`.
        '';
      in "${file}";
    };
  };
}
