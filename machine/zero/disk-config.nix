let
  disk = "/dev/sda";
in {
  disko.devices = {
    disk.primary = {
      type = "disk";
      device = "${disk}";

      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };

          swap = {
            size = "6G";
            content = {type = "swap";};
          };

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
