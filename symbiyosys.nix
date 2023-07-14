{
  pkgs,
  stdenv,

  python,
  git,

  hdx-versions,
}:

with pkgs.lib;

stdenv.mkDerivation {
  name = "symbiyosys";

  src = pkgs.fetchgit {
    url = "https://github.com/YosysHQ/sby.git";
    inherit (hdx-versions.symbiyosys) rev sha256;
  };

  makeFlags = [
    "PREFIX=$(out)"
  ];

  propagatedBuildInputs = [
    python.pkgs.click
  ];
}
