{
  pkgs,
  lib,
  stdenv,
  hdx-config,
  hdx-inputs,
  python,
  boost,
}: let
  src = hdx-inputs.nextpnr-xilinx;
  version = "0.6dev1+g${lib.substring 0 7 src.rev}";
in
  stdenv.mkDerivation {
    pname = "nextpnr-xilinx";
    inherit version src;

    nativeBuildInputs = [pkgs.cmake];

    buildInputs = builtins.attrValues {
      inherit
        python
        boost
        ;
      inherit (pkgs) eigen;
      inherit (python.pkgs) apycula;
    };

    cmakeFlags = ["-DARCH=xilinx"];
  }
