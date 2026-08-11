{
  description = "rlyeh — headless agent-focused personal server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Private sops-encrypted secrets, shared across machines. The
    # github.com-secrets host alias (modules/network.nix) makes rlyeh
    # authenticate with its host key, registered as a read-only deploy key.
    secrets = {
      url = "git+ssh://git@github.com-secrets/FelipeAfonso/secrets.git";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, disko, home-manager, sops-nix, ... }: {
    nixosConfigurations.rlyeh = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        ./hosts/rlyeh
      ];
    };
  };
}
