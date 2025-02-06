{ lib, pkgs, config, ... }:
let
  cfg = config.install-unattended;

  beep = lib.getExe pkgs.beep;
  disko-install = lib.getExe' pkgs.disko "disko-install";

  install-unattended = pkgs.writeShellScriptBin "install-unattended" ''
    #!${pkgs.runtimeShell}

    ${beep} -f 440 -n -f 392

    read -p "Press any key to install configuration '${cfg.flake}#${cfg.conf}' onto disk... " -n1 -s

    echo
    echo

    ${beep} -f 440

    #--

    ${disko-install} --flake ${cfg.flake}#${cfg.conf} --disk ${cfg.disk} ${cfg.flake.nixosConfigurations.${cfg.conf}.config.disko.devices.disk.${cfg.disk}.device}

    echo "Use Ctrl+Alt+Suppr. to reboot !"
    sleep infinity
  '';
in
{
  options.install-unattended = {
    enable = lib.mkEnableOption "Enable the unattended installation of the provided flake's configuration";

    flake = lib.mkOption {
      type = lib.types.package;
      description = ''
        The flake providing the configuration to be installed
      '';
    };

    conf = lib.mkOption {
      type = lib.types.str;
      description = ''
        The name of the `nixosConfigurations` to install
      '';
    };

    disk = lib.mkOption {
      type = lib.types.str;
      description = ''
        The name of the disko disk to provision with the configuration
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    services.getty = {
      autologinUser = lib.mkForce null;
      extraArgs = [ "--skip-login" ];

      helpLine = lib.mkForce ''
        This is an automatic installation for a system based on the `#${cfg.conf}` configuration,
        it will partition the disks and provision the system using `disko-install`.

        [!!] This will erase everything on the system.
      '';

      loginProgram = "${lib.getExe install-unattended}";
    };
  };
}

