{
  pkgs,
  stdenv,

  python,
  git,

  symbiyosys_rev,
  symbiyosys_git_sha256,
}:

with pkgs.lib;

stdenv.mkDerivation {
  name = "symbiyosys";

  src = pkgs.fetchgit {
    url = "https://github.com/YosysHQ/sby.git";
    rev = symbiyosys_rev;
    sha256 = symbiyosys_git_sha256;
  };

  makeFlags = [
    "PREFIX=$(out)"
  ];

  propagatedBuildInputs = [
    python.pkgs.click
  ];
}
