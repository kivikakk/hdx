{
  pkgs,
  lib,
  stdenv,
  hdx-config,
  hdx-inputs,
}:
stdenv.mkDerivation {
  pname = "z3";
  version = "4.12.2";
  src = hdx-inputs.z3;

  patches = [
    ../patches/z3.pc.cmake.in.patch
  ];

  nativeBuildInputs = with pkgs; [
    cmake
    hdx-config.python
    gmp
  ];

  cmakeFlags = [
    "-DZ3_USE_LIB_GMP=ON"
  ];

  enableParallelBuilding = true;
}
