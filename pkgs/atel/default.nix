{
  lib,
  rustPlatform,
  llvmPackages,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "atel";
  version = "0.0.0-devel";

  nativeBuildInputs = [llvmPackages.bintools];

  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = {
    description = "Various telecom functionalities, handling & management for alcat.tel's network.";
    license = with lib.licenses; [
      agpl3Only
    ];
    maintainers = [];
  };
}
