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
}
