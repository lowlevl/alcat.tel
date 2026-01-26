{lib, ...}: {
  networking = {
    bridges.dect0 = {
      interfaces = ["enp2s0f0"];
    };

    interfaces.dect0.ipv4.addresses = lib.singleton {
      address = "10.127.0.254";
      prefixLength = 24;
    };
  };

  services.kea.dhcp4 = {
    enable = true;

    settings = {
      interfaces-config.interfaces = ["dect0"];

      lease-database = {
        type = "memfile";
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
      };

      subnet4 = lib.singleton {
        subnet = "10.127.0.0/24";

        pools = lib.singleton {pool = "10.127.0.1 - 10.127.0.253";};
        reservations = [
          {
            hw-address = "";
            ip-address = "10.127.0.1";
          }
        ];
      };
    };
  };
}
