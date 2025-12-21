{
  lib,
  rustPlatform,
  llvmPackages,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "atelco";
  version = "0.0.0-devel";

  nativeBuildInputs = [llvmPackages.bintools];

  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  SQLX_OFFLINE = true; # use cached compile-time checking.

  meta = {
    mainProgram = "atelco";
    description = "Various telecom functionalities, handling & management for alcat.tel's network.";
    license = with lib.licenses; [
      agpl3Only
    ];
    maintainers = [];
  };
}
