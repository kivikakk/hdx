{
  pkgs,
  stdenv,

  python,
  git,

  hdx-versions,
}:

with pkgs.lib;

stdenv.mkDerivation {
  name = "z3";

  src = pkgs.fetchgit {
    url = "https://github.com/Z3Prover/z3.git";
    inherit (hdx-versions.z3) rev sha256;
  };

  patches = [
    ./patches/z3.pc.cmake.in.patch
  ];

  nativeBuildInputs = with pkgs; [
    cmake
    python
    gmp
  ];

  cmakeFlags = [
    "-DZ3_USE_LIB_GMP=ON"
  ];

  enableParallelBuilding = true;
}
