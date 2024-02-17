{
  stdenv,
  lib,
  hdxInputs,
  clang,
  readline,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "abc";
  version = "0.37dev1+g${lib.substring 0 7 hdxInputs.abc.rev}";

  src = hdxInputs.abc;

  nativeBuildInputs = [clang];

  buildInputs = [readline];

  makeFlags = [
    "CC=clang"
    "CXX=clang++"
    "ABC_USE_LIBSTDCXX=1"
    "ABC_USE_NAMESPACE=abc"
    "abc"
    "libabc.a"
  ];
  preBuild = ''
    makeFlagsArray+=(ARCHFLAGS="-DABC_USE_STDINT_H -Wno-c++11-narrowing")
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp abc $out/bin/abc

    mkdir -p $out/lib
    cp libabc.a $out/lib/libabc.a
  '';

  enableParallelBuilding = true;
})
