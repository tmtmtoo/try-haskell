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
        haskellPackages = pkgs.haskellPackages;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            haskellPackages.haskell-language-server
            haskellPackages.cabal-install
            haskellPackages.hlint
            haskellPackages.fourmolu
            haskellPackages.ghcid
            pkgs.ghc
          ];
          LANG = "C.UTF-8";
        };
      });
}