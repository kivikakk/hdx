{
  pkgs,
  stdenv,
  llvmPackages,
  icestorm ? null,
  trellis ? null,
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

      buildInputs = with pkgs; [
        hdx-config.python
        boost
        eigen
        hdx-config.python.pkgs.apycula
        llvmPackages.openmp
      ];

      cmakeFlags =
        [
          "-DUSE_OPENMP=ON"
          ("-DARCH=" + builtins.concatStringsSep ";" hdx-config.nextpnr.archs)
        ]
        ++
        # XXX Is this going to build anyway even if disabled? How lazy is string interpolation?
        (optional (nextpnr-support.enabled icestorm) "-DICESTORM_INSTALL_PREFIX=${icestorm}");

      enableParallelBuilding = false;
    }
    // optionalAttrs (nextpnr-support.enabled trellis) {
      TRELLIS_INSTALL_PREFIX = trellis;
      TRELLIS_LIBDIR = "${trellis}/lib/trellis";
    })
