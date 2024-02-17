{
  description = "A build system for Yosys and Amaranth, and a framework for building projects with them";

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
      pkgs = import nixpkgs {inherit system;};
      python = pkgs.python311;

      amaranthSetupHook =
        pkgs.makeSetupHook {
          name = "amaranth-setup-hook.sh";
          propagatedBuildInputs = builtins.attrValues {
            inherit
              (python.pkgs)
              pip
              editables
              ;
          };
          substitutions = {
            pythonInterpreter = python.interpreter;
            pythonSitePackages = python.sitePackages;
          };
          passthru.provides.setupHook = true;
        }
        ./amaranth-setup-hook.sh;

      callPackage = pkgs.lib.callPackageWith env;
      env =
        pkgs
        // {
          inherit python;
          inherit amaranthSetupHook;
          hdxInputs = inputs;

          amaranth = callPackage ./pkgs/amaranth.nix {};
          amaranth-boards = callPackage ./pkgs/amaranth-boards.nix {};
          amaranth-stdio = callPackage ./pkgs/amaranth-stdio.nix {};
          yosys = callPackage ./pkgs/yosys.nix {};
          abc = callPackage ./pkgs/abc.nix {};
          hdx = callPackage ./pkgs/hdx.nix {};
        };
    in rec {
      packages.default = env.hdx;

      formatter = pkgs.alejandra;

      devShells = {
        default = env.hdx;
        #amaranth = import ./amaranth-dev-shell.nix {inherit hdx;};
        #yosys-amaranth = import ./yosys-amaranth-dev-shell.nix {inherit hdx;};
      };
    });
}
