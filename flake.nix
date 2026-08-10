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

    # Private sops-encrypted secrets, shared across machines. Uncomment once
    # the repo exists (see README "Secrets"), then wire it up in
    # modules/secrets.nix.
    # secrets = {
    #   url = "git+ssh://git@github.com/FelipeAfonso/secrets.git";
    #   flake = false;
    # };
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
