{
  pkgs,
  stdenv,

  python,
  git,

  icestorm ? null,
  trellis ? null,

  hdx-config,
  hdx-versions,
  nextpnr-support,
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
    pkg-config
    cmake
  ] ++ nextpnr-support.enabled_pkgs;

  buildInputs = with pkgs; [
    python
    eigen
    (boost.override { inherit python; enablePython = true; })
  ];

  cmakeFlags = [
    ("-DARCH=" + builtins.concatStringsSep ";" hdx-config.nextpnr.archs)
  ];

  enableParallelBuilding = true;

} // optionalAttrs (nextpnr-support.enabled icestorm) {
  ICESTORM_INSTALL_PREFIX = icestorm;

} // optionalAttrs (nextpnr-support.enabled trellis) {
  TRELLIS_INSTALL_PREFIX = trellis;
})
