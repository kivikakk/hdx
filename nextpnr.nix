{
  pkgs,
  stdenv,
  fetchgit,
  fetchzip,

  python,
  git,

  icestorm,

  nextpnr_rev,
  nextpnr_git_sha256,
}:

stdenv.mkDerivation {
  name = "nextpnr";

  src = fetchgit {
    name = "nextpnr";
    url = "https://github.com/YosysHQ/nextpnr.git";
    rev = nextpnr_rev;
    sha256 = nextpnr_git_sha256;
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
    icestorm
  ];

  buildInputs = with pkgs; [
    python
    eigen
    (boost.override { inherit python; enablePython = true; })
  ];

  cmakeFlags = [
    "-DARCH=ice40"
    # TODO "-DARCH=ice40;ecp5"
  ];

  ICESTORM_INSTALL_PREFIX = icestorm;

  enableParallelBuilding = true;
}
