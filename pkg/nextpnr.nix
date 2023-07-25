{
  pkgs,
  stdenv,
  icestorm,
  trellis,
  hdx-config,
  hdx-versions,
  nextpnr-support,
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

    buildInputs = with pkgs;
      [
        hdx-config.python
        boost
        eigen
        hdx-config.python.pkgs.apycula
      ]
      ++ (optional (nextpnr-support.enabled icestorm) icestorm)
      ++ (optional (nextpnr-support.enabled trellis) trellis);

    cmakeFlags =
      [
        "-DARCH=${concatStringsSep ";" (sort lessThan hdx-config.nextpnr.archs)}"
      ]
      ++ (optional (nextpnr-support.enabled icestorm) "-DICESTORM_INSTALL_PREFIX=${icestorm}")
      ++ (optional (nextpnr-support.enabled trellis) "-DTRELLIS_INSTALL_PREFIX=${trellis}")
      ++ (optional (nextpnr-support.enabled trellis) "-DTRELLIS_LIBDIR=${trellis}/lib/trellis");
  }
