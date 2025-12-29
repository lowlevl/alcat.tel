{pkgs, ...}:
pkgs.mkShell {
  buildInputs = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt
    pkgs.clippy
    pkgs.rust-analyzer

    pkgs.sqlx-cli
  ];

  DATABASE_URL = "sqlite:///tmp/atelco.sqlite?mode=rwc";
}
