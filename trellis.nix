{
  pkgs,
  stdenv,

  python,
  git,

  trellis_rev,
  trellis_git_sha256,
}:

stdenv.mkDerivation {
  name = "trellis";

  src = pkgs.fetchgit {
    name = "prjtrellis";
    url = "https://github.com/YosysHQ/prjtrellis.git";
    rev = trellis_rev;
    sha256 = trellis_git_sha256;
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
