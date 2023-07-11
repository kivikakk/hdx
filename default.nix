{
  pkgs ? import <nixpkgs> {},

  hdxPython ? pkgs.python311,

  yosys_rev ? "14d50a176d59a5eac95a57a01f9e933297251d5b",
  yosys_git_sha256 ? "1SiCI4hs59Ebn3kh7GESkgHuKySPaGPRvxWH7ajSGRM=",
  abc_rev ? "bb64142b07794ee685494564471e67365a093710",
  abc_tgz_sha256 ? "Qkk61Lh84ervtehWskSB9GKh+JPB7mI1IuG32OSZMdg=",
}:

let
  callPackage = pkgs.lib.callPackageWith (pkgs // hdx);

  hdx = {
    inherit pkgs;

    stdenv = pkgs.gcc13Stdenv;

    inherit hdxPython;
    # Throwing options here feels suss as fuck.
    inherit yosys_rev yosys_git_sha256 abc_rev abc_tgz_sha256;

    yosys = callPackage ./yosys {};

    all = with hdx; [
      yosys
    ];
  };

in hdx
