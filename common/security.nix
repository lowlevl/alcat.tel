# - Security-context related settings
{...}: {
  #- User-related settings
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  #- Firewall-related settings
  networking.firewall.enable = true;
  service.openssh.openFirewall = true;
}
