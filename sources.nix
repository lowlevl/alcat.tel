{
  realm = "alcat.tel's telephony network";
  banner = ''
      ┓        ┓
    ┏┓┃┏┏┓╋ ╋┏┓┃
    ┗┻┗┗┗┻┗•┗┗ ┗
  '';

  modules.disko =
    builtins.fetchTarball {
      url = "https://github.com/nix-community/disko/archive/v1.11.0.tar.gz";
      sha256 = "13brimg7z7k9y36n4jc1pssqyw94nd8qvgfjv53z66lv4xkhin92";
    }
    + "/module.nix";

  modules.sops-nix =
    builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/07af005bb7d60c7f118d9d9f5530485da5d1e975.tar.gz";
      sha256 = "1r9ism27mhjwx9hhj2p10s051z5p0czgjdi04dm7w3kl69xhd47c";
    }
    + "/modules/sops";
}
