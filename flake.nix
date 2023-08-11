{
  inputs = {
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
    amaranth = {
      url = github:amaranth-lang/amaranth;
      flake = false;
    };
    amaranth-boards = {
      url = github:amaranth-lang/amaranth-boards;
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

      checks = {
        ensure-ecppack-call-works =
          pkgs.runCommand "ensure-ecppack-call-works" {
            nativeBuildInputs = [packages.default];
          } ''
            ecppack ${packages.default.trellis}/share/trellis/misc/basecfgs/empty_lfe5u-85f.config /dev/null
            touch $out
          '';
      };
    });
}
