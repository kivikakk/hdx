{
  git,
  lib,
  hdxInputs,
  python,
  amaranth,
}:
python.pkgs.buildPythonPackage rec {
  pname = "amaranth-boards";
  version = "0.1.0dev1+g${lib.substring 0 7 src.rev}";
  format = "pyproject";
  src = hdxInputs.amaranth-boards;

  nativeBuildInputs = [
    git
    python.pkgs.setuptools-scm
    amaranth
  ];

  preBuild = ''
    export SETUPTOOLS_SCM_PRETEND_VERSION="${version}"
  '';

  doCheck = false; # PEP 517 blah blah
}
