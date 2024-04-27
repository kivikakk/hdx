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
      url = github:YosysHQ/abc?rev=03da96f12fb4deb153cc0dc73936df346ecd4bcf;
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

      hdxSetupHook =
        pkgs.makeSetupHook {
          name = "hdx-setup-hook.sh";
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
        ./hdx-setup-hook.sh;

      callPackage = pkgs.lib.callPackageWith env;
      env =
        pkgs
        // {
          inherit python;
          hdxInputs = inputs;
          inherit hdxSetupHook;

          amaranth = callPackage ./pkgs/amaranth.nix {};
          amaranth-boards = callPackage ./pkgs/amaranth-boards.nix {};
          amaranth-stdio = callPackage ./pkgs/amaranth-stdio.nix {};
          yosys = callPackage ./pkgs/yosys.nix {};
          abc = callPackage ./pkgs/abc.nix {};
          hdx = callPackage ./pkgs/hdx.nix {};
          rainhdx = callPackage ./rainhdx {};
        };
    in {
      packages.default = env.hdx;
      packages.rainhdx = env.rainhdx;

      formatter = pkgs.alejandra;

      devShells = rec {
        default = env.hdx;

        amaranth = env.amaranth.overridePythonAttrs (prev: {
          name = "hdx-amaranth";
          src = null;

          nativeBuildInputs =
            prev.nativeBuildInputs
            ++ lib.remove env.amaranth env.hdx.propagatedBuildInputs
            ++ [hdxSetupHook];

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
                if pkgs.stdenv.isDarwin
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
    })
    // {
      templates.rainhdx = {
        path = ./rainhdx/template;
        description = "A minimal FPGA project using Amaranth";
      };
    };
}
