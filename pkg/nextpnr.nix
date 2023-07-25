{
  pkgs,
  stdenv,
  icestorm ? null,
  trellis ? null,
  hdx-config,
  hdx-versions,
  boost,
}:
with pkgs.lib;
  stdenv.mkDerivation {
    name = "nextpnr";

    src = pkgs.fetchFromGitHub {
      owner = "YosysHQ";
      repo = "nextpnr";
      inherit (hdx-versions.nextpnr) rev sha256;
    };

    nativeBuildInputs = with pkgs; [
      cmake
    ];

    buildInputs = with pkgs; [
      hdx-config.python
      boost
      eigen
      hdx-config.python.pkgs.apycula
      icestorm
      trellis
    ];

    cmakeFlags =
      [
        "-DARCH=${concatStringsSep ";" (unique (sort lessThan hdx-config.nextpnr.archs))}"
      ]
      ++ (optional (icestorm != null) "-DICESTORM_INSTALL_PREFIX=${icestorm}")
      ++ (optional (trellis != null) "-DTRELLIS_INSTALL_PREFIX=${trellis}")
      ++ (optional (trellis != null) "-DTRELLIS_LIBDIR=${trellis}/lib/trellis");
  }
