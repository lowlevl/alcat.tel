{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  openssl,
  sqlite,
  libtiff,
  spandsp,
  speex,
  gsm,
  doxygen,
  autoreconfHook,
  pkg-config,
  dahdi-linux,
  ...
}: let
  version = "033daef7003fd5811c9a7e5f6d8a994f786ba708";
  hash = "sha256-uCH4PBukLs+HQOUPc4+LZY3dnbEshpXPF37Nb5IfwVE=";
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "yate";
    inherit version;

    buildInputs = [
      openssl.dev
      sqlite.dev
      libtiff.dev
      spandsp.dev
      speex.dev
      gsm
    ];
    nativeBuildInputs = [
      autoreconfHook
      pkg-config
    ];
    enableParallelBuilding = true;

    src = fetchFromGitHub {
      owner = "lowlevl";
      repo = "yate";
      rev = version;
      inherit hash;
    };

    passthru = callPackage ./passthru.nix {};

    preConfigure = ''
      configureFlagsArray+=(
        # Use `CFLAGS` because `CPPFLAGS` is not propagated correctly
        "CFLAGS=-I${dahdi-linux.dev}/usr/include"
      )
      ./yate-config.sh
    '';
    configureFlags = [
      "--with-doxygen=${lib.getExe doxygen}"
      "--with-spandsp=${spandsp.dev}/include"
      "--with-libspeex=${speex.dev}/include"
      "--with-libgsm=${gsm}/include/gsm"
      "--enable-sse2=yes"
      "--verbose"
    ];

    meta = {
      maintainers = [];
      # Yate's license is GPL with an exception for linking with
      # OpenH323 and PWlib (licensed under MPL).
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "yate";
      homepage = "https://yate.ro/";
      description = "Yet another telephony engine";
    };
  })
