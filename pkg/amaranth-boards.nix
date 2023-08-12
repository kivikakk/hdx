{
  pkgs,
  lib,
  amaranth,
  hdx-inputs,
  hdx-config,
}: let
  python = hdx-config.python;
  pythonPkgs = python.pkgs;
in
  pythonPkgs.buildPythonPackage rec {
    pname = "amaranth-boards";
    version = "0.1.0dev1+g${lib.substring 0 7 src.rev}";
    src = hdx-inputs.amaranth-boards;
    postUnpack = hdx-config.leaveDotGitWorkaround;

    nativeBuildInputs = [
      pkgs.git
      pythonPkgs.setuptools-scm
      amaranth
    ];
  }
