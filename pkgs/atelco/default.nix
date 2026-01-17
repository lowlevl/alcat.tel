{
  lib,
  naersk',
  ...
}:
naersk'.buildPackage {
  src = ./.;
  enableParallelBuilding = true;

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
