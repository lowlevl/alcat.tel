{
  stdenv,
  lib,
  pkgs,
}: let
  yate = pkgs.callPackage ../pkgs/yate.nix {};
in
  stdenv.mkDerivation rec {
    name = "alcat.tel-share";

    nativeBuildInputs = [];
    buildInputs = [pkgs.php];

    sourceRoot = ".";
    srcs = [
      ./scripts
      ./wave
    ];

    dontBuild = true;
    installPhase = let
      links = [
        "libyate.php"
        "libyateivr.php"
        "libyatechan.php"
        "libvoicemail.php"
        "libeliza.js"
        "libchatbot.js"
        "eliza.js"
        "libyate.py"
        "Yate.pm"
      ];
    in
      ''
        install -m 0755 -D scripts/* -t $out/scripts
        install -m 0644 -D wave/* -t $out/wave
      ''
      + builtins.concatStringsSep "\n" (builtins.map (path: ''ln -v -s "${yate}/share/yate/scripts/${path}" "$out/scripts/${path}"'') links);

    meta = {
      description = "The shareable for yate in the alcat.tel system";
      license = lib.licenses.gpl3;
      maintainers = [];
      platforms = lib.platforms.all;
    };
  }
