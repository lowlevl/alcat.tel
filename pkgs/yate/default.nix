{
  stdenv,
  pkgs,
  lib,
  ...
}: let
  dahdi-linux = pkgs.linuxPackages.callPackage ../dahdi-linux {};
in
  stdenv.mkDerivation (finalAttrs: rec {
    pname = "yate";
    version = "6.4.1-3";

    nativeBuildInputs = [
      pkgs.autoreconfHook
      pkgs.pkg-config
    ];
    buildInputs = [
      pkgs.openssl.dev
      pkgs.sqlite.dev
      pkgs.libtiff.dev
      pkgs.spandsp.dev
      pkgs.speex.dev
      pkgs.gsm
    ];
    enableParallelBuilding = false; # Breaks the libminiwebrtc.a's `ar` call

    passthru = import ./passthru.nix {
      inherit pkgs lib;
      self = finalAttrs.finalPackage;
    };

    src = pkgs.fetchFromGitHub {
      owner = "lowlevl";
      repo = "${pname}";
      rev = "05c1518de2f4f75eebe55abf1c038425f58bd51e";
      sha256 = "7LR+a5oHtHvdlaPnrl84qFeiOzMr2kjMiylMTjZEcsg=";
    };

    preConfigure = ''
      configureFlagsArray+=(
        # Use `CFLAGS` because `CPPFLAGS` is not propagated correctly
        "CFLAGS=-I${dahdi-linux}/usr/include"
      )
      ./yate-config.sh
    '';
    configureFlags = [
      "--with-doxygen=${lib.getExe pkgs.doxygen}"
      "--with-spandsp=${pkgs.spandsp.dev}/include"
      "--with-libspeex=${pkgs.speex.dev}/include"
      "--with-libgsm=${pkgs.gsm}/include/gsm"
      "--enable-sse2=yes"
      "--verbose"
    ];

    meta = {
      description = "Yet another telephony engine";
      homepage = "https://yate.ro/";
      # Yate's license is GPL with an exception for linking with
      # OpenH323 and PWlib (licensed under MPL).
      license = lib.licenses.gpl2Only;
      maintainers = [];
      platforms = lib.platforms.linux;
      mainProgram = "yate";
    };
  })
