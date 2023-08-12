{
  pkgs,
  lib,
  stdenv,
  python,
  hdx-inputs,
}:
stdenv.mkDerivation {
  pname = "z3";
  version = "4.12.2";
  src = hdx-inputs.z3;

  patches = [
    ../patches/z3.pc.cmake.in.patch
  ];

  nativeBuildInputs = builtins.attrValues {
    inherit python;
    inherit
      (pkgs)
      cmake
      gmp
      ;
  };

  cmakeFlags = [
    "-DZ3_USE_LIB_GMP=ON"
  ];

  enableParallelBuilding = true;
}
