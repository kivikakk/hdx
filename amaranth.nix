{
  pkgs,
  fetchgit,

  python,
  git,

  yosys,

  amaranth_rev,
  amaranth_git_sha256,
}:

python.pkgs.buildPythonPackage rec {
  name = "amaranth";
  format = "pyproject";

  src = fetchgit {
    url = "https://github.com/amaranth-lang/amaranth.git";
    rev = amaranth_rev;
    sha256 = amaranth_git_sha256;
    leaveDotGit = true;  # needed for setuptools-scm
  };

  nativeBuildInputs = with python.pkgs; [
    pkgs.git
    setuptools
    setuptools-scm
    yosys  # not available in shell without
  ];

  buildInputs = with python.pkgs; [
    pyvcd
    jinja2
    yosys
  ];

  doCheck = false;
}
