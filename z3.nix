{
  pkgs,
  stdenv,

  python,
  git,

  z3_rev,
  z3_git_sha256,
}:

with pkgs.lib;

# Doesn't really want to build with GCC right now.
# That's okay.  Neither do I.
pkgs.llvmPackages_16.stdenv.mkDerivation {
  name = "z3";

  src = pkgs.fetchgit {
    url = "https://github.com/Z3Prover/z3.git";
    rev = z3_rev;
    sha256 = z3_git_sha256;
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
