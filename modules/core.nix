{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "felipe" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap.enable = true;
  services.fstrim.enable = true;
  services.smartd.enable = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    htop
    tree
    ripgrep
  ];
}
