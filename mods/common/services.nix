# - common/services: common services on all machines
{atel, ...}: {
  networking.firewall.enable = true;

  services.openssh = {
    enable = true;
    startWhenNeeded = true;

    banner = ''
      ${atel.banner}

      [!!] This realm is the property of `alcat.tel`.
    '';

    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
