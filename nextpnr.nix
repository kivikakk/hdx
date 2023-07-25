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
  stdenv.mkDerivation ({
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

      cmakeFlags = [
        "-DARCH=${concatStringsSep ";" (sort lessThan hdx-config.nextpnr.archs)}"
      ];
    }
    // optionalAttrs (nextpnr-support.enabled icestorm) {
      ICESTORM_INSTALL_PREFIX = icestorm;
    }
    // optionalAttrs (nextpnr-support.enabled trellis) {
      TRELLIS_INSTALL_PREFIX = trellis;
      TRELLIS_LIBDIR = "${trellis}/lib/trellis";
    })
