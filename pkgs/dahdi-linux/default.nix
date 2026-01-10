{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  perl,
}: let
  fwbase = "https://downloads.digium.com/pub/telephony/firmware/releases";
  fws = {
    dahdi-fw-oct6114-032.version = "1.05.01";
    dahdi-fw-oct6114-032.sha256 = "egBgcyAtZ+RfHV/x6cboZj5gVs753ExauuhqEBjbNJw=";

    dahdi-fw-oct6114-064.version = "1.05.01";
    dahdi-fw-oct6114-064.sha256 = "VrrB8gJMduz5tvQJku7qKaH77mdrsqN6BYF5us+7HJE=";

    dahdi-fw-oct6114-128.version = "1.05.01";
    dahdi-fw-oct6114-128.sha256 = "4RRnSdIFxBYDubdoUsP4EE2sIz0AJdcA2yRQTRDJl3U=";

    dahdi-fw-oct6114-256.version = "1.05.01";
    dahdi-fw-oct6114-256.sha256 = "X+UDaidmzw6KlosMWLcAUH2G4c3pKWykNxcMxiapx5w=";

    dahdi-fw-tc400m.version = "MR6.12";
    dahdi-fw-tc400m.sha256 = "Ed2NAJgJ5B/Jo6NnZvWf9z0pB17t5bhyQzHZpuUll3Q=";

    dahdi-fwload-vpmadt032.version = "1.25.0";
    dahdi-fwload-vpmadt032.sha256 = "P/Js+AVV/XRwtDqHxR0DwdsqdavNRWHXn2m2xIKY5KE=";

    dahdi-fw-hx8.version = "2.06";
    dahdi-fw-hx8.sha256 = "RJqz/QPVXYCOmZ77dnfNBN4gK5LJ/LA5U5p+SKOagPU=";

    dahdi-fw-vpmoct032.version = "1.12.0";
    dahdi-fw-vpmoct032.sha256 = "axmc+DbxUPnLNfdj8PUC+1LPonJKRJtQBCnHRpc5BK0=";

    dahdi-fw-te820.version = "1.76";
    dahdi-fw-te820.sha256 = "W4I+JYKOLBxlSIhq1Aiy4x28jNFxcMUlknktnHVKGZw=";

    dahdi-fw-te133.version = "7a001e";
    dahdi-fw-te133.sha256 = "URwZZilaIN9nO7h68wJF8K0WXv1sy5K02O1TXKf1rGU=";

    dahdi-fw-te134.version = "780017";
    dahdi-fw-te134.sha256 = "mffEEL9H0qWuaH1xflFEjOW1KsqQKDC/Ob/+aDFQ+i0=";

    dahdi-fw-te435.version = "13001e";
    dahdi-fw-te435.sha256 = "yPVdV8wL8zLo2Wzfn/bdDjIvM1geHvwkwrmg4MXrfuQ=";

    dahdi-fw-te436.version = "10017";
    dahdi-fw-te436.sha256 = "CYD0qNGRxocqon2XF1gEbw54J6wWFUnyzBsO6rCukzM=";

    dahdi-fw-a8a.version = "1d0017";
    dahdi-fw-a8a.sha256 = "UGT5h3uK7Jmxn9V5iCFv4anAt8B4U907MrWlWre0GOY=";

    dahdi-fw-a8b.version = "1f001e";
    dahdi-fw-a8b.sha256 = "CaiZJ4YwngJapgtACix9ISJqybtvG2b1YqXn6dyJKwM=";

    dahdi-fw-a4a.version = "a0017";
    dahdi-fw-a4a.sha256 = "1baraFHkMa/P7C7MOdlfqI/jk5/9suPU8opDyr8w6Vs=";

    dahdi-fw-a4b.version = "d001e";
    dahdi-fw-a4b.sha256 = "4Dmvi+w2QHt04d2evdSboHdGntp51OYJNyHtKDbUU28=";
  };

  wanpipe.version = "7.0.38";
  wanpipe.sha256 = "lSZu3YO9i7Qn9H96OTZXlZNqzA1uLjoeSCvQFbupD6I=";

  version = "648016d6b3a06f7ec75c17ef94ffa17be59eebcf";
  hash = "sha256-G9mEhZeWNOujWXoCejWeuV0msdhodAAFR8LY8zaBTLQ=";
in
  stdenv.mkDerivation {
    name = "dahdi-linux-${version}-${kernel.version}";

    hardeningDisable = ["pic"];
    nativeBuildInputs = kernel.moduleBuildDependencies ++ [perl];
    enableParallelBuilding = true;

    sourceRoot = "source";
    srcs =
      [
        (fetchFromGitHub {
          owner = "asterisk";
          repo = "dahdi-linux";
          rev = "${version}";
          inherit hash;
        })
        (builtins.fetchurl {
          url = "https://ftp.sangoma.com/linux/current_wanpipe/wanpipe-${wanpipe.version}.tgz";
          inherit (wanpipe) sha256;
        })
      ]
      #-- Additionnal tarballs required by dahdi-linux's Makefiles
      ++ lib.mapAttrsToList (package: {
        version,
        sha256,
      }:
        builtins.fetchurl {
          url = "${fwbase}/${package}-${version}.tar.gz";
          inherit sha256;
        })
      fws;

    unpackCmd = ''
      local source="$curSrc"
      local destination="$(stripHash "$source")"

      cp -r --preserve=mode,timestamps --reflink=auto -- "$source" "$destination"
    '';
    postUnpack = ''
      mv *.tar.gz "$sourceRoot/drivers/dahdi/firmware"

      install -d "$sourceRoot/drivers/staging"
      tar xvf wanpipe-*.tgz "wanpipe-${wanpipe.version}/OSLEC/echo" --strip-components=2
      mv -v echo "$sourceRoot/drivers/staging"

      patchShebangs --build "$sourceRoot"
    '';

    patches = [
      ./00-revert-tdm410-tdm800-disable.patch
    ];

    makeFlags = [
      "KVERS=${kernel.modDirVersion}"
      "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    ];

    outputs = [
      "out"
      "dev"
    ];

    installFlags = [
      "DESTDIR=$(out)"
    ];
    postInstall = ''
      moveToOutput "usr/include/dahdi" "$dev"
    '';

    meta = {
      maintainers = [];
      license = lib.licenses.gpl2;
      platforms = lib.platforms.linux;
      homepage = "https://github.com/asterisk/dahdi-linux";
      description = "An open-source device driver framework and a set of HW drivers for E1/T1, ISDN digital and FXO/FXS analog cards.";
    };
  }
