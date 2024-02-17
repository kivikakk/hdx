{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
    flake-utils.url = github:numtide/flake-utils;

    amaranth = {
      url = github:amaranth-lang/amaranth;
      flake = false;
    };
    amaranth-boards = {
      url = github:amaranth-lang/amaranth-boards;
      flake = false;
    };
    amaranth-stdio = {
      url = github:amaranth-lang/amaranth-stdio;
      flake = false;
    };

    yosys = {
      url = github:YosysHQ/yosys;
      flake = false;
    };
    abc = {
      url = github:YosysHQ/abc?rev=896e5e7dedf9b9b1459fa019f1fa8aa8101fdf43;
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      hdx = import ./hdx.nix {
        inherit system pkgs;
        hdx-inputs = inputs;
      };
    in rec {
      packages.default = hdx;

      formatter = pkgs.alejandra;

      devShells = {
        default = hdx;
        amaranth = import ./amaranth-dev-shell.nix {inherit hdx;};
        yosys-amaranth = import ./yosys-amaranth-dev-shell.nix {inherit hdx;};
      };
    });
}
