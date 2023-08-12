{
  pkgs,
  lib,
  stdenv,
  hdx-config,
  hdx-inputs,
}:
stdenv.mkDerivation rec {
  pname = "symbiyosys";
  version = "yosys-0.32dev1+g${lib.substring 0 7 src.rev}";

  src = hdx-inputs.symbiyosys;

  buildInputs = [
    pkgs.coreutils
  ];

  postPatch = ''
    substituteInPlace sbysrc/sby_core.py --replace "/usr/bin/env" "${pkgs.coreutils}/bin/env"
  '';

  makeFlags = [
    "PREFIX=$(out)"
  ];

  propagatedBuildInputs = [
    hdx-config.python.pkgs.click
  ];
}
