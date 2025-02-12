let
  disk = "/dev/sda";
  ram = "4G";
in {
  disko.devices = {
    disk.primary = {
      type = "disk";
      device = "${disk}";
      imageSize = "16G"; # Set an image size for disko debugging

      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };

          swap = {
            size = "${ram}";
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
