{
  pkgs,
  lib,
  amaranth,
  python,
  hdx-inputs,
  leaveDotGitWorkaround,
}: let
  pythonPkgs = python.pkgs;
in
  pythonPkgs.buildPythonPackage rec {
    pname = "amaranth-stdio";
    version = "0.1.0dev1+g${lib.substring 0 7 src.rev}";
    src = hdx-inputs.amaranth-stdio;
    postUnpack = leaveDotGitWorkaround;

    nativeBuildInputs = builtins.attrValues {
      inherit (pkgs) git;
      inherit (pythonPkgs) setuptools-scm;
      inherit amaranth;
    };
  }
