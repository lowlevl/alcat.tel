{pkgs, ...}:
pkgs.mkShell rec {
  buildInputs = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt
    pkgs.clippy
    pkgs.rust-analyzer

    pkgs.sqlx-cli
  ];

  AT_DATABASE = "sqlite:///tmp/atelco.sqlite";
  DATABASE_URL = AT_DATABASE;
}
