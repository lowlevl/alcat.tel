# - common/services: common services on all machines
{...}: {
  networking.firewall.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
