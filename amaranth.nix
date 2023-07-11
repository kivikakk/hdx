{
  fetchgit,

  python,
  git,

  yosys,

  amaranth_dev_mode,
  amaranth_rev,
  amaranth_git_sha256,
}:

python.pkgs.buildPythonPackage rec {
  name = "amaranth";
  format = "pyproject";

  src = if amaranth_dev_mode then ./amaranth else (fetchgit {
    url = "https://github.com/amaranth-lang/amaranth.git";
    rev = amaranth_rev;
    sha256 = amaranth_git_sha256;
    leaveDotGit = true;
  });

  nativeBuildInputs = [
    git
  ];

  propagatedBuildInputs = with python.pkgs; [
    setuptools
    setuptools-scm
    pyvcd
    jinja2
    yosys
  ];

  doCheck = false;
}
