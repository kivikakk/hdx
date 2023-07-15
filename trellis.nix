{
  pkgs,
  stdenv,
  python,
  git,
  hdx-versions,
}:
stdenv.mkDerivation {
  name = "trellis";

  src = pkgs.fetchFromGitHub {
    name = "prjtrellis";
    owner = "YosysHQ";
    repo = "prjtrellis";
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
    (boost.override {
      inherit python;
      enablePython = true;
    })
  ];
}
