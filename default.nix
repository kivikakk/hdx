{
  nixpkgs ? import <nixpkgs> {},

  git ? nixpkgs.git,
  python ? nixpkgs.python311,

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
}:

let
  callPackage = nixpkgs.lib.callPackageWith (nixpkgs // hdx);

  hdx = {
    pkgs = nixpkgs // ours;

    stdenv = nixpkgs.gcc13Stdenv;

    inherit git python ours;

    # Throwing options here feels suss as fuck.
    inherit amaranth_rev amaranth_git_sha256s;
    inherit yosys_rev yosys_git_sha256 abc_rev abc_tgz_sha256;
    inherit icestorm_rev icestorm_git_sha256;
  } // ours;

  ours = {
    amaranth = callPackage ./amaranth.nix {};
    yosys = callPackage ./yosys.nix {};
    icestorm = callPackage ./icestorm.nix {};
  };

in hdx
