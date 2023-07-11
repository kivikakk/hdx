{
  pkgs ? import <nixpkgs> {},

  git ? pkgs.git,
  python ? pkgs.python311,

  amaranth_dev_mode ? false,
  amaranth_rev ? "ea36c806630904aa5b5c18042207a62ca9045d12",
  amaranth_git_sha256 ? "OcgXn5sgTssl1Iiu/YLZ2fUgfCZXomsF/MDc85BCCaQ=",
  yosys_rev ? "14d50a176d59a5eac95a57a01f9e933297251d5b",
  yosys_git_sha256 ? "1SiCI4hs59Ebn3kh7GESkgHuKySPaGPRvxWH7ajSGRM=",
  abc_rev ? "bb64142b07794ee685494564471e67365a093710",
  abc_tgz_sha256 ? "Qkk61Lh84ervtehWskSB9GKh+JPB7mI1IuG32OSZMdg=",
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // hdxpkgs);

  hdxPython = python.withPackages (ps: [ hdxpkgs.amaranth ]);

  hdxpkgs = {
    inherit pkgs;
    stdenv = pkgs.gcc13Stdenv;

    inherit git python;

    # Throwing options here feels suss as fuck.
    inherit yosys_rev yosys_git_sha256 abc_rev abc_tgz_sha256;
    inherit amaranth_dev_mode amaranth_rev amaranth_git_sha256;

    amaranth = callPackage ./amaranth.nix {};
    yosys = callPackage ./yosys.nix {};

    hdx = with hdxpkgs; [
      amaranth
      yosys
      hdxPython
    ];
  };

in hdxpkgs
