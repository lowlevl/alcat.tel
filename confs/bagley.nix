#- The messaging and voice server.

{ self
, ...
}: {
  imports = [
    self.inputs.disko.nixosModules.default

    ../common/base.nix
    ../common/remote.nix
  ];

  networking.hostName = "bagley";

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    imageSize = "16G"; # Set an image size for disko debugging
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # for grub MBR
        };

        swap = {
          size = "4G";
          content = {
            type = "swap";
          };
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
}
