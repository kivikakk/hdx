{
  pkgs ? import <nixpkgs> {},
  opts ? {},
}:
with pkgs.lib;
  makeOverridable (
    opts @ {...}: let
      hdx-config = import ./nix/hdx-config.nix {inherit pkgs;} opts;
      hdx-versions = import ./nix/hdx-versions.nix;

      stdenv = hdx-config.stdenv;

      # I feel iffy about not mixing in pkgs here too -- especially given we
      # override Boost and it'd be easy to forget to include it in a module's
      # args list and have the pkgs one accidentally used in a "with pkgs; [
      # ... ]" section --, but it was causing me bugs when icestorm/trellis
      # were falling through to base packages while I was trying to work out a
      # nice way to conditionally build.  Maybe later when I know this stuff
      # better.
      callPackage = callPackageWith env;
      env =
        {
          inherit pkgs;
          inherit hdx-config hdx-versions;
          inherit stdenv;

          boost = callPackage ./nix/boost.nix {};
        }
        // ours;

      nextpnrArchs =
        {}
        // optionalAttrs (elem "ice40" hdx-config.nextpnr.archs) {icestorm = callPackage ./pkg/icestorm.nix {};}
        // optionalAttrs (elem "ecp5" hdx-config.nextpnr.archs) {trellis = callPackage ./pkg/trellis.nix {};};

      ours =
        {}
        // optionalAttrs (hdx-config.amaranth.enable) {
          amaranth = callPackage ./pkg/amaranth.nix {};
          amaranth-boards = callPackage ./pkg/amaranth-boards.nix {};
        }
        // optionalAttrs (hdx-config.yosys.enable) {yosys = callPackage ./pkg/yosys.nix {};}
        // optionalAttrs (hdx-config.nextpnr.enable) ({nextpnr = callPackage ./pkg/nextpnr.nix {inherit nextpnrArchs;};} // nextpnrArchs)
        // optionalAttrs (hdx-config.symbiyosys.enable) (
          {symbiyosys = callPackage ./pkg/symbiyosys.nix {};}
          // optionalAttrs (elem "z3" hdx-config.symbiyosys.solvers) {z3 = callPackage ./pkg/z3.nix {};}
          // optionalAttrs (elem "yices" hdx-config.symbiyosys.solvers) {yices = callPackage ./pkg/yices.nix {};}
        );
    in
      stdenv.mkDerivation
      {
        name = "hdx";

        dontUnpack = true;

        propagatedBuildInputs = [
          hdx-config.python
        ];

        buildInputs = attrValues ours;

        # Yuck.
        installPhase =
          ''
            mkdir $out
          ''
          + (let
            f = pkg: ''
              cp -a ${pkg}/* $out
              find $out -type d -exec chmod u+w '{}' \;
              rm -f $out/nix-support/propagated-build-inputs
            '';
          in
            concatMapStringsSep "\n" f (attrValues ours));

        passthru =
          {inherit pkgs ours;} // ours;

        AMARANTH_USE_YOSYS = ours.amaranth.AMARANTH_USE_YOSYS or null;
      }
  )
  opts
