{
  pkgs,
  stdenv,
  fetchgit,
  fetchzip,

  python,
  git,

  icestorm_rev,
  icestorm_git_sha256,
}:

stdenv.mkDerivation {
  name = "icestorm";

  src = fetchgit {
    name = "icestorm";
    url = "https://github.com/YosysHQ/icestorm.git";
    rev = icestorm_rev;
    sha256 = icestorm_git_sha256;
  };

  configurePhase = ''
    export PREFIX="$prefix"
  '';

  nativeBuildInputs = with pkgs; [
    pkg-config
    python
    libftdi
  ];
}
