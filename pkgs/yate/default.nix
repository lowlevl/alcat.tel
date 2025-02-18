{
  stdenv,
  lib,
  pkgs,
}: let
  dahdi-linux = pkgs.linuxPackages.callPackage ../dahdi-linux {};
in
  stdenv.mkDerivation rec {
    pname = "yate";
    version = "6.4.0-1";

    nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config];
    buildInputs = [pkgs.openssl pkgs.sqlite];

    src = pkgs.fetchFromGitHub {
      owner = "yatevoip";
      repo = "${pname}";
      rev = "25a425eb0effe5c187552844ac9c2bf1e498819e";
      sha256 = "SlSpgNNEiHWjgPB7zim2gVRYcTENS4bOLdECLGXzRqI=";
    };

    patches = [
      ./00-fix-analog-module.patch
    ];

    preConfigure = ''
      configureFlagsArray+=(
        # Use `CFLAGS` because `CPPFLAGS` is not propagated correctly
        "CFLAGS=-I${dahdi-linux}/usr/include -DDEBUG"
      )
      ./yate-config.sh
    '';

    configureFlags = [
      "--with-doxygen=${lib.getExe pkgs.doxygen}"
      "--enable-sse2=yes"
    ];

    meta = {
      description = "Yet another telephony engine";
      homepage = "https://yate.ro/";
      # Yate's license is GPL with an exception for linking with
      # OpenH323 and PWlib (licensed under MPL).
      license = lib.licenses.gpl2Only;
      maintainers = [];
      platforms = [
        "i686-linux"
        "x86_64-linux"
      ];
      mainProgram = "yate";
    };
  }
