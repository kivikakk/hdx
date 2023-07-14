{
  pkgs ? import <nixpkgs> {},

  git ? pkgs.git,
  python ? pkgs.python311,

  amaranth_rev ? "ea36c806630904aa5b5c18042207a62ca9045d12",
  amaranth_git_sha256s ? {
    # XXX Well, isn't this the worst? Until I workaround NixOS/nixpkgs#8567
    # better.
    x86_64-linux = "OcgXn5sgTssl1Iiu/YLZ2fUgfCZXomsF/MDc85BCCaQ=";
    aarch64-darwin = "afMA0nj+HQD0rxNqgf6dtI1lkUCetirnxQToDxE987g=";
  },

  yosys_rev ? "14d50a176d59a5eac95a57a01f9e933297251d5b",
  yosys_git_sha256 ? "1SiCI4hs59Ebn3kh7GESkgHuKySPaGPRvxWH7ajSGRM=",
  abc_rev ? "bb64142b07794ee685494564471e67365a093710",
  abc_tgz_sha256 ? "Qkk61Lh84ervtehWskSB9GKh+JPB7mI1IuG32OSZMdg=",

  icestorm_rev ? "d20a5e9001f46262bf0cef220f1a6943946e421d",
  icestorm_git_sha256 ? "dEBmxO2+Rf/UVyxDlDdJGFAeI4cu1wTCbneo5I4gFG0=",

  trellis_rev ? "e830a28077e1a789d32e75841312120ae624c8d6",
  trellis_git_sha256 ? "COC5iPJHkpfB6rZUAz1P6EvpdqfbSLsc59dhAm1nXMA=",

  nextpnr_rev ? "54b2045726fc3fe77857c05c81a5ab77e98ba851",
  nextpnr_git_sha256 ? "BhNQKACh8ls2cnQ9tMn8YSrpEiIz5nqhcnuYLnEbJXw=",
  nextpnr_archs ? ["ice40" "ecp5"],

  symbiyosys_rev ? "fbbbab235f4ecdce6353cb6c9062d790c450dddc",
  symbiyosys_git_sha256 ? "F2kylUuX1cbVnyEvObRr4l8EoqJIzZJjwpFyNyy+iP8=",

  z3_rev ? "z3-4.12.2",
  z3_git_sha256 ? "DTgpKEG/LtCGZDnicYvbxG//JMLv25VHn/NaF307JYA=",
}:

with pkgs.lib;

let
  # I feel iffy about not mixing in pkgs here too, but it was causing me
  # bugs when icestorm/trellis were falling through to base packages while
  # I was trying to work out a nice way to conditionally build.  Maybe
  # later when I know this stuff better.
  callPackage = callPackageWith env;
  env = {
    inherit pkgs;
    stdenv = pkgs.gcc13Stdenv;

    inherit git python;

    # Throwing options here feels suss as fuck.
    inherit amaranth_rev amaranth_git_sha256s;
    inherit yosys_rev yosys_git_sha256 abc_rev abc_tgz_sha256;
    inherit icestorm_rev icestorm_git_sha256;
    inherit trellis_rev trellis_git_sha256;
    inherit nextpnr_rev nextpnr_git_sha256;
    nextpnr_archs = sort lessThan nextpnr_archs;
    inherit symbiyosys_rev symbiyosys_git_sha256;
    inherit z3_rev z3_git_sha256;

    nextpnr-support = callPackage ./nextpnr-support.nix {};
  }
    // toplevels
    // nextpnr-arch-deps
  ;

  toplevels = {
    amaranth = callPackage ./amaranth.nix {};
    yosys = callPackage ./yosys.nix {};
    nextpnr = callPackage ./nextpnr.nix {};
    symbiyosys = callPackage ./symbiyosys.nix {};
    z3 = callPackage ./z3.nix {};
  };

  nextpnr-arch-deps = {
    icestorm = callPackage ./icestorm.nix {};
    trellis = callPackage ./trellis.nix {};
  };

  selected-nextpnr-arch-deps =
    filterAttrs (_: env.nextpnr-support.enabled) nextpnr-arch-deps;

  all = toplevels // selected-nextpnr-arch-deps;

in
{
  inherit pkgs all;
} // all
