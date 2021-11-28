{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {self, nixpkgs, home-manager}: {

    homeConfigurations = {
      eashwar = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-darwin";
        homeDirectory = "/Users/eashwar";
        username = "eashwar";
        configuration.imports = [
          ./modules/home-manager.nix
          ./modules/packages.nix
          ./modules/git.nix
        ];
      };
    };
  };
}
