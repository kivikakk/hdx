{
  pkgs,
  lib,
  stdenv,
  hdx-inputs,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "abc";
  version = "0.37dev1+g${lib.substring 0 7 hdx-inputs.abc.rev}";

  src = hdx-inputs.abc;

  nativeBuildInputs = builtins.attrValues {
    inherit
      (pkgs)
      clang
      ;
  };

  buildInputs = builtins.attrValues {
    inherit
      (pkgs)
      readline
      ;
  };

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
