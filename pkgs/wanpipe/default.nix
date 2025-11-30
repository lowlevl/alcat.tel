{
  lib,
  stdenv,
  autoconf,
  automake,
  libtool,
  bison,
  flex,
  ncurses,
  kernel,
}: let
  version = "7.0.38";
  sha256 = "lSZu3YO9i7Qn9H96OTZXlZNqzA1uLjoeSCvQFbupD6I=";
in
  stdenv.mkDerivation {
    name = "wanpipe-${version}-${kernel.version}";

    hardeningDisable = ["pic"];
    nativeBuildInputs = kernel.moduleBuildDependencies ++ [autoconf automake libtool bison flex ncurses.dev];
    enableParallelBuilding = true;

    src = builtins.fetchurl {
      url = "https://ftp.sangoma.com/linux/current_wanpipe/wanpipe-${version}.tgz";
      inherit sha256;
    };

    preConfigure = "patchShebangs ./patches";

    patches = [
      ./00-fix-class_create-call.patch
      ./01-fix-ktimer-size-determination.patch
      ./02-fix-proto_ops-struct-def.patch
      # ./03-fix-unsafe-printf-uses.patch
      ./04-disable-faulty-ncurses-check.patch
      ./05-missing-header-defs.patch

      ./tes.patch
    ];

    makeFlags = [
      "KVER=${kernel.modDirVersion}"
      "KMOD=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    ];

    installFlags = [
      "DESTDIR=$(out)"
    ];

    meta = {
      maintainers = [];
      license = lib.licenses.gpl2;
      platforms = lib.platforms.linux;
      homepage = "https://sangomakb.atlassian.net/wiki/spaces/TC/pages/51839456/Telephony+Cards+-+Card+Driver-+Overview";
      description = "A suite of kernel device drivers and utilities that enable all Sangoma TDM boards.";
    };
  }
