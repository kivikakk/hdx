inputs @ {
  pkgs,
  system,
  hdx-inputs,
  ...
}: let
  inherit (pkgs) lib stdenv;
  inherit (lib) optionalAttrs elem;

  callPackage = lib.callPackageWith env;
  env =
    rec {
      inherit system pkgs lib stdenv;
      inherit hdx-inputs;
      inherit ours;
      python = pkgs.python311;

      leaveDotGitWorkaround = ''
        # Workaround for NixOS/nixpkgs#8567.
        pushd source
        git init
        git config user.email charlotte@lottia.net
        git config user.name Charlotte
        git add -A .
        git commit -m "leaveDotGit workaround"
        popd
      '';

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
    }
    // ours;

  ours = {
    amaranth = callPackage ./pkgs/amaranth.nix {};
    amaranth-boards = callPackage ./pkgs/amaranth-boards.nix {};
    amaranth-stdio = callPackage ./pkgs/amaranth-stdio.nix {};
    yosys = callPackage ./pkgs/yosys.nix {};
    abc = callPackage ./pkgs/abc.nix {};
  };
in
  stdenv.mkDerivation rec {
    name = "hdx";

    dontUnpack = true;

    propagatedBuildInputs =
      [
        env.python
        pkgs.nextpnr
        pkgs.symbiyosys
        pkgs.z3_4_12
        pkgs.yices
        pkgs.icestorm
        pkgs.trellis
      ]
      ++ builtins.attrValues ours;

    passthru = env;

    buildInputs = [pkgs.makeWrapper];

    AMARANTH_USE_YOSYS = ours.amaranth.AMARANTH_USE_YOSYS;

    installPhase = ''
      for b in ${env.python}/bin/*; do
        makeWrapper "$b" "$out/bin/$(basename "$b")" --inherit-argv0 --set AMARANTH_USE_YOSYS ${AMARANTH_USE_YOSYS}
      done
    '';
  }
