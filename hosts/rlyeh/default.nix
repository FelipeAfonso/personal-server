{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/core.nix
    ../../modules/network.nix
    ../../modules/agents.nix
    ../../modules/dev.nix
    ../../modules/headless-gfx.nix
    ../../modules/secrets.nix
  ];

  networking.hostName = "rlyeh";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.felipe = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
    # TTY/KVM login only (SSH is key-only). Change with `passwd` after first boot.
    initialPassword = "cthulhu-fhtagn";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICE5I6PLbSND+zuRx8RqdCTBBZ3B9Va7SMxIeIviVoWh fmunhozafonso@gmail.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINCHbUa1tAmxUSsBOGplrJ4zLTN/X5Tkrc2FE/Hv0BBX termius-iphone"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9R66qFE6vCvA7QuOuF6/JqXQFgZCYTOFk1b846dvN7 yuggoth"
    ];
  };

  # Single-human tailnet-only box; passwordless sudo keeps unattended agent
  # runs from stalling on a prompt. Accepted trade — see README.
  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.felipe = import ../../home/felipe;
  };

  system.stateVersion = "25.11";
}
