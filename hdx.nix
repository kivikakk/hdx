inputs @ {
  system,
  hdx-inputs,
  ...
}: let
  pkgs = inputs.pkgs.extend (final: prev: {
    python311 = import ./pkgs/python.nix {python = prev.python311;};
  });

  inherit (pkgs) lib stdenv;
  inherit (lib) optionalAttrs elem;

  hdx-config = {
    amaranth.enable = true;
    yosys.enable = true;
    nextpnr = {
      enable = true;
      archs = ["generic" "ice40" "ecp5"];
    };
    symbiyosys = {
      enable = true;
      solvers = ["yices" "z3"];
    };
  };

  # I feel iffy about not mixing in pkgs here too -- especially given we
  # override Boost and it'd be easy to forget to include it in a module's
  # args list and have the pkgs one accidentally used in a "with pkgs; [
  # ... ]" section --, but it was causing me bugs when icestorm/trellis
  # were falling through to base packages while I was trying to work out a
  # nice way to conditionally build.  Maybe later when I know this stuff
  # better.
  callPackage = lib.callPackageWith env;
  env =
    rec {
      inherit system pkgs lib stdenv;
      inherit hdx-inputs hdx-config;
      inherit ours;
      python = pkgs.python311;

      boost = callPackage ./pkgs/boost.nix {};

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

  nextpnrArchs =
    {}
    // optionalAttrs (elem "ice40" hdx-config.nextpnr.archs) {icestorm = callPackage ./pkgs/icestorm.nix {};}
    // optionalAttrs (elem "ecp5" hdx-config.nextpnr.archs) {trellis = callPackage ./pkgs/trellis.nix {};};

  ours =
    {}
    // optionalAttrs (hdx-config.amaranth.enable) {
      amaranth = callPackage ./pkgs/amaranth.nix {};
      amaranth-boards = callPackage ./pkgs/amaranth-boards.nix {};
    }
    // optionalAttrs (hdx-config.yosys.enable) {yosys = callPackage ./pkgs/yosys.nix {};}
    // optionalAttrs (hdx-config.nextpnr.enable) ({nextpnr = callPackage ./pkgs/nextpnr.nix {inherit nextpnrArchs;};} // nextpnrArchs)
    // optionalAttrs (hdx-config.symbiyosys.enable) (
      {symbiyosys = callPackage ./pkgs/symbiyosys.nix {};}
      // optionalAttrs (elem "z3" hdx-config.symbiyosys.solvers) {z3 = callPackage ./pkgs/z3.nix {};}
      // optionalAttrs (elem "yices" hdx-config.symbiyosys.solvers) {yices = callPackage ./pkgs/yices.nix {};}
    );
in
  stdenv.mkDerivation ({
      name = "hdx";

      dontUnpack = true;

      propagatedBuildInputs =
        [
          env.python
        ]
        ++ builtins.attrValues ours;

      passthru = env;
    }
    // optionalAttrs (hdx-config.amaranth.enable) rec {
      buildInputs = [pkgs.makeWrapper];

      AMARANTH_USE_YOSYS = ours.amaranth.AMARANTH_USE_YOSYS;

      installPhase = ''
        for b in ${env.python}/bin/*; do
          makeWrapper "$b" "$out/bin/$(basename "$b")" --inherit-argv0 --set AMARANTH_USE_YOSYS ${AMARANTH_USE_YOSYS}
        done
      '';
    })
