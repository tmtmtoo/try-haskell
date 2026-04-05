{
  description = "try-haskell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        haskell = pkgs.haskellPackages.override {
          overrides = self: super: {
            try-haskell = self.callCabal2nix "try-haskell" ./. { };
          };
        };
      in
      {
        packages.default = pkgs.haskell.lib.justStaticExecutables
          haskell.try-haskell;

        devShells.default = haskell.shellFor {
          packages = p: [ p.try-haskell ];
          withHoogle = true;
          buildInputs = [
            haskell.haskell-language-server
            haskell.cabal-install
            haskell.hlint
            haskell.fourmolu
            haskell.ghcid
          ];
        };
      });
}
