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
        // toplevels
        // nextpnr-arch-deps;

      toplevels = {
        amaranth = callPackage ./pkg/amaranth.nix {};
        yosys = callPackage ./pkg/yosys.nix {};
        nextpnr = callPackage ./pkg/nextpnr.nix {inherit nextpnr-support;};
        symbiyosys = callPackage ./pkg/symbiyosys.nix {};
        z3 = callPackage ./pkg/z3.nix {};
      };

      nextpnr-support = callPackage ./nix/nextpnr-support.nix {};

      nextpnr-arch-deps = {
        icestorm = callPackage ./pkg/icestorm.nix {};
        trellis = callPackage ./pkg/trellis.nix {};
      };

      selected-nextpnr-arch-deps =
        filterAttrs (_: nextpnr-support.enabled) nextpnr-arch-deps;

      ours = toplevels // selected-nextpnr-arch-deps;
    in
      stdenv.mkDerivation
      {
        name = "hdx";
        buildInputs = attrValues ours;
        passthru =
          {
            inherit pkgs ours;
          }
          // ours;
      }
  )
  opts
