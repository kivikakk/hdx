{
  pkgs ? import <nixpkgs> {},

  python ? pkgs.python311,

  yosys_rev ? "14d50a176d59a5eac95a57a01f9e933297251d5b",
  yosys_git_sha256 ? "1SiCI4hs59Ebn3kh7GESkgHuKySPaGPRvxWH7ajSGRM=",
  abc_rev ? "bb64142b07794ee685494564471e67365a093710",
}:

rec {
  yosys = pkgs.callPackage ./yosys { python = python; };
}
