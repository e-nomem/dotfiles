{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self, nixpkgs, home-manager, flake-utils}:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in {
      packages = {
        homeConfigurations.eashwar = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./modules/direnv.nix
            ./modules/git.nix
            ./modules/gpg.nix
            ./modules/home-manager.nix
            ./modules/packages.nix
          ];
        };
      };
    }
  );
}
