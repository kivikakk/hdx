{
  pkgs,

  python,
  git,

  yosys,

  hdx-versions,
}:

with pkgs.lib;

python.pkgs.buildPythonPackage rec {
  name = "amaranth";
  format = "pyproject";

  src = pkgs.fetchgit {
    url = "https://github.com/amaranth-lang/amaranth.git";
    inherit (hdx-versions.amaranth) rev;
    sha256 = getAttr pkgs.system hdx-versions.amaranth.sha256s;
    leaveDotGit = true;  # needed for setuptools-scm
  };

  nativeBuildInputs = with python.pkgs; [
    pkgs.git
    setuptools
    setuptools-scm
  ];

  buildInputs = with python.pkgs; [
    pyvcd
    jinja2
    yosys
  ];

  doCheck = false;
}
