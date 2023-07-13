{
  pkgs,
  stdenv,

  python,
  git,

  icestorm ? null,
  trellis ? null,

  nextpnr_rev,
  nextpnr_git_sha256,
  nextpnr_archs,
  nextpnr-support,
}:

with pkgs.lib;

stdenv.mkDerivation ({
  name = "nextpnr";

  src = pkgs.fetchgit {
    name = "nextpnr";
    url = "https://github.com/YosysHQ/nextpnr.git";
    rev = nextpnr_rev;
    sha256 = nextpnr_git_sha256;
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
    ("-DARCH=" + builtins.concatStringsSep ";" nextpnr_archs)
  ];

  enableParallelBuilding = true;

} // optionalAttrs (nextpnr-support.enabled icestorm) {
  ICESTORM_INSTALL_PREFIX = icestorm;

} // optionalAttrs (nextpnr-support.enabled trellis) {
  TRELLIS_INSTALL_PREFIX = trellis;
})
