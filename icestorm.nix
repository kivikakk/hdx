{
  pkgs,
  stdenv,

  python,
  git,

  hdx-versions,
}:

stdenv.mkDerivation {
  name = "icestorm";

  src = pkgs.fetchgit {
    url = "https://github.com/YosysHQ/icestorm.git";
    inherit (hdx-versions.icestorm) rev sha256;
  };

  patches = [
    ./patches/icebox-Makefile.patch
  ];

  makeFlags = [
    "PREFIX=$(out)"
  ];

  nativeBuildInputs = with pkgs; [
    pkg-config
    python
    libftdi
  ];
}
