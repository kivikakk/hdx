{
  pkgs,
  stdenv,
  hdx-config,
  hdx-versions,
}:
with pkgs.lib;
  stdenv.mkDerivation {
    name = "z3";

    src = pkgs.fetchFromGitHub {
      owner = "Z3Prover";
      repo = "z3";
      inherit (hdx-versions.z3) rev sha256;
    };

    patches = [
      ./patches/z3.pc.cmake.in.patch
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
