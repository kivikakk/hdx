{
  pkgs,
  lib,
  stdenv,
  hdx-config,
  hdx-inputs,
}:
stdenv.mkDerivation rec {
  pname = "yices";
  version = "2.6.4dev1+g${lib.substring 0 7 src.rev}";

  src = hdx-inputs.yices;

  nativeBuildInputs = with pkgs; [
    autoreconfHook
    gperf
    gmp
  ];

  enableParallelBuilding = true;
}
