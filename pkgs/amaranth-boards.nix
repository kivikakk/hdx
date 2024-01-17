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
    pname = "amaranth-boards";
    version = "0.1.0dev1+g${lib.substring 0 7 src.rev}";
    src = hdx-inputs.amaranth-boards;
    postUnpack = leaveDotGitWorkaround;

    nativeBuildInputs = builtins.attrValues {
      inherit (pkgs) git;
      inherit (pythonPkgs) setuptools-scm;
      inherit amaranth;
    };

    doCheck = false; # PEP 517 blah blah
  }
