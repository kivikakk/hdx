{
  pkgs,
  yosys,
  hdx-config,
  hdx-versions,
}:
with pkgs.lib;
  hdx-config.python.pkgs.buildPythonPackage rec {
    name = "amaranth";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "amaranth-lang";
      repo = "amaranth";
      inherit (hdx-versions.amaranth) rev;
      sha256 = hdx-versions.amaranth.sha256s.${pkgs.system};
      leaveDotGit = true; # needed for setuptools-scm
    };

    nativeBuildInputs = with hdx-config.python.pkgs; [
      pkgs.git
      setuptools
      setuptools-scm
    ];

    buildInputs = with hdx-config.python.pkgs; [
      pyvcd
      jinja2
      yosys
    ];

    doCheck = false;
  }
