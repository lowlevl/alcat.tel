{
  stdenv,
  lib,
  kernel,
  kmod,
  pkgs,
}: let
  fwsUrl = "https://downloads.digium.com/pub/telephony/firmware/releases";
  fws = {
    dahdi-fw-oct6114-032 = "1.05.01";
    dahdi-fw-oct6114-064 = "1.05.01";
    dahdi-fw-oct6114-128 = "1.05.01";
    dahdi-fw-oct6114-256 = "1.05.01";
    dahdi-fw-tc400m = "MR6.12";
    dahdi-fwload-vpmadt032 = "1.25.0";
    dahdi-fw-hx8 = "2.06";
    dahdi-fw-vpmoct032 = "1.12.0";
    dahdi-fw-te820 = "1.76";
    dahdi-fw-te133 = "7a001e";
    dahdi-fw-te134 = "780017";
    dahdi-fw-te435 = "13001e";
    dahdi-fw-te436 = "10017";
    dahdi-fw-a8a = "1d0017";
    dahdi-fw-a8b = "1f001e";
    dahdi-fw-a4a = "a0017";
    dahdi-fw-a4b = "d001e";
  };
in
  stdenv.mkDerivation rec {
    pname = "dahdi";
    version = "3.4.0";

    sourceRoot = "source";
    srcs =
      [
        (builtins.fetchTarball {
          url = "https://github.com/asterisk/dahdi-linux/releases/download/v${version}/dahdi-linux-${version}.tar.gz";
          sha256 = "08w1fy4hm9amia12zbwb791l4zmg7axdws660w40dckmnvh5qw6y";
        })
      ]
      #-- Additionnal firmware tarballs required by DAHDI's Makefiles
      ++ lib.mapAttrsToList (package: version: builtins.fetchurl "${fwsUrl}/${package}-${version}.tar.gz") fws;

    unpackCmd = ''
      local source="$curSrc"
      local destination="$(stripHash "$source")"

      cp -r --preserve=mode,timestamps --reflink=auto -- "$source" "$destination"
    '';
    postUnpack = ''
      mv *.tar.gz "${sourceRoot}/drivers/dahdi/firmware"
      patchShebangs --build "${sourceRoot}"
    '';

    hardeningDisable = ["pic"];
    nativeBuildInputs = kernel.moduleBuildDependencies ++ [pkgs.perl];

    makeFlags = [
      "KVERS=${kernel.modDirVersion}"
      "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "DESTDIR=$(out)"
    ];

    meta = {
      description = "An open-source device driver framework and a set of HW drivers for E1/T1, ISDN digital and FXO/FXS analog cards.";
      homepage = "https://github.com/asterisk/dahdi-linux";
      license = lib.licenses.gpl2;
      maintainers = [];
      platforms = lib.platforms.linux;
    };
  }
