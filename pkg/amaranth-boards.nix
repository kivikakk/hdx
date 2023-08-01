{
  pkgs,
  amaranth,
  hdx-config,
  hdx-versions,
}:
with pkgs.lib; let
  python = hdx-config.python;
  pythonPkgs = python.pkgs;
in
  pythonPkgs.buildPythonPackage rec {
    name = "amaranth-boards";
    src = pkgs.fetchFromGitHub {
      owner = "amaranth-lang";
      repo = "amaranth-boards";
      inherit (hdx-versions.amaranth-boards) rev sha256;
    };

    postUnpack = hdx-config.leaveDotGitWorkaround;

    nativeBuildInputs = [
      pkgs.git
      pythonPkgs.setuptools-scm
      amaranth
    ];
  }
