{
  pkgs,
  stdenv,

  python,
  git,

  hdx-versions,
}:

stdenv.mkDerivation {
  name = "trellis";

  src = pkgs.fetchgit {
    name = "prjtrellis";
    url = "https://github.com/YosysHQ/prjtrellis.git";
    inherit (hdx-versions.trellis) rev sha256;
  };

  sourceRoot = "prjtrellis/libtrellis";

  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
    python
    libftdi
  ];

  buildInputs = with pkgs; [
    (boost.override { inherit python; enablePython = true; })
  ];
}
