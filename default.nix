{pkgs ? import <nixpkgs> {}}:
with pkgs.lib;
  makeOverridable (
    opts @ {...}: let
      hdx-config = (import ./config.nix {inherit pkgs;}).process opts;
      hdx-versions = import ./versions.nix;

      # I feel iffy about not mixing in pkgs here too, but it was causing me
      # bugs when icestorm/trellis were falling through to base packages while
      # I was trying to work out a nice way to conditionally build.  Maybe
      # later when I know this stuff better.
      callPackage = callPackageWith env;
      env =
        {
          inherit pkgs;
          inherit hdx-config hdx-versions;
          inherit (hdx-config) stdenv llvmPackages;

          boost = pkgs.boost.override {
            inherit (hdx-config) stdenv python;
            enablePython = true;
            extraB2Args = [
              # To build on LLVM 16.
              "define=BOOST_NO_CXX98_FUNCTION_BASE"
              "cxxflags=-Wno-enum-constexpr-conversion"
            ];
          };
        }
        // toplevels
        // nextpnr-arch-deps;

      toplevels = {
        amaranth = callPackage ./amaranth.nix {};
        yosys = callPackage ./yosys.nix {};
        nextpnr = callPackage ./nextpnr.nix {inherit nextpnr-support;};
        symbiyosys = callPackage ./symbiyosys.nix {};
        z3 = callPackage ./z3.nix {};
      };

      nextpnr-support = callPackage ./nextpnr-support.nix {};

      nextpnr-arch-deps = {
        icestorm = callPackage ./icestorm.nix {};
        trellis = callPackage ./trellis.nix {};
      };

      selected-nextpnr-arch-deps =
        filterAttrs (_: nextpnr-support.enabled) nextpnr-arch-deps;

      all = toplevels // selected-nextpnr-arch-deps;
    in
      {
        inherit pkgs all;
      }
      // all
  ) {}
