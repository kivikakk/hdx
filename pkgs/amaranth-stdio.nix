{
  git,
  lib,
  hdxInputs,
  python,
  amaranth,
}:
python.pkgs.buildPythonPackage rec {
  pname = "amaranth-stdio";
  version = "0.1.0dev1+g${lib.substring 0 7 src.rev}";
  format = "pyproject";
  src = hdxInputs.amaranth-stdio;

  nativeBuildInputs = [
    git
    python.pkgs.pdm-backend
    amaranth
  ];
}
