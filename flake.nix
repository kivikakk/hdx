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
      inherit (pkgs) lib;
      python = pkgs.python311;

      amaranthSetupHook =
        pkgs.makeSetupHook {
          name = "amaranth-setup-hook.sh";
          propagatedBuildInputs = [
            python.pkgs.pip
            python.pkgs.editables
          ];
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
          hdxInputs = inputs;

          amaranth = callPackage ./pkgs/amaranth.nix {};
          amaranth-boards = callPackage ./pkgs/amaranth-boards.nix {};
          amaranth-stdio = callPackage ./pkgs/amaranth-stdio.nix {};
          yosys = callPackage ./pkgs/yosys.nix {};
          abc = callPackage ./pkgs/abc.nix {};
          hdx = callPackage ./pkgs/hdx.nix {};
        };
    in {
      packages.default = env.hdx;

      formatter = pkgs.alejandra;

      devShells = rec {
        default = env.hdx;

        amaranth = env.amaranth.overridePythonAttrs (prev: {
          name = "hdx-amaranth";
          src = null;

          nativeBuildInputs =
            prev.nativeBuildInputs
            ++ lib.remove env.amaranth env.hdx.propagatedBuildInputs
            ++ [amaranthSetupHook];

          preShellHook = builtins.readFile ./amaranth-shell-hook.sh;
          postShellHook = ''
            # Start shell back where we came from.
            cd $HDX_START
          '';

          doCheck = false;
        });

        amaranth-yosys = amaranth.overridePythonAttrs (prev: {
          name = "hdx-amaranth+yosys";

          nativeBuildInputs =
            lib.remove env.yosys prev.nativeBuildInputs
            ++ env.yosys.nativeBuildInputs
            ++ [
              (
                if builtins.elem system lib.platforms.darwin
                then pkgs.lldb
                else pkgs.gdb
              )
              pkgs.verilog
            ];

          buildInputs =
            lib.remove env.yosys prev.buildInputs
            ++ env.yosys.buildInputs;

          preShellHook =
            lib.replaceStrings ["@Makefile.conf.hdx@"] [
              (env.yosys.overrideAttrs {
                makefileConfPrefix = "$(HDX_OUT)";
                extraMakefileConf = ''
                  ENABLE_DEBUG=1
                  STRIP=echo hdx: Not doing this: strip
                '';
              })
              .makefileConf
            ]
              (builtins.readFile
                ./amaranth-yosys-shell-hook.sh);
        });
      };
    });
}
