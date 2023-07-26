{
  pkgs,
  stdenv,
  icestorm ? null,
  trellis ? null,
  hdx-config,
  hdx-versions,
  boost,
}:
with pkgs.lib; let
  src = pkgs.fetchFromGitHub {
    owner = "YosysHQ";
    repo = "nextpnr";
    inherit (hdx-versions.nextpnr) rev sha256;
  };

  chipdbs = {
    generic = null;
    ice40 = stdenv.mkDerivation {
      name = "nextpnr-chipdb-ice40";
      inherit src;
      nativeBuildInputs = [
        pkgs.cmake
        hdx-config.python
      ];
      sourceRoot = "source/ice40";
      cmakeFlags = ["-DICESTORM_INSTALL_PREFIX=${icestorm}"];
      installPhase = ''
        cp -r chipdb $out
      '';
    };
    ecp5 = stdenv.mkDerivation {
      name = "nextpnr-chipdb-ecp5";
      inherit src;
      nativeBuildInputs = [
        pkgs.cmake
        hdx-config.python
      ];
      sourceRoot = "source/ecp5";
      cmakeFlags = [
        "-DTRELLIS_INSTALL_PREFIX=${trellis}"
        "-DTRELLIS_LIBDIR=${trellis}/lib/trellis"
      ];
      installPhase = ''
        cp -r chipdb $out
      '';
    };
  };
in
  stdenv.mkDerivation {
    name = "nextpnr";
    inherit src;

    nativeBuildInputs = [
      pkgs.cmake
    ] ++ attrVals hdx-config.nextpnr.archs chipdbs;

    buildInputs = with pkgs;
      [
        hdx-config.python
        boost
        eigen
        hdx-config.python.pkgs.apycula
        icestorm
        trellis
      ];

    cmakeFlags =
      [
        "-DARCH=${concatStringsSep ";" hdx-config.nextpnr.archs}"
      ]
      ++ (optional (icestorm != null) "-DICE40_CHIPDB=${chipdbs.ice40}")
      ++ (optional (icestorm != null) "-DICESTORM_INSTALL_PREFIX=${icestorm}")
      ++ (optional (trellis != null) "-DECP5_CHIPDB=${chipdbs.ecp5}")
      ++ (optional (trellis != null) "-DTRELLIS_INSTALL_PREFIX=${trellis}")
      ++ (optional (trellis != null) "-DTRELLIS_LIBDIR=${trellis}/lib/trellis");
  }
