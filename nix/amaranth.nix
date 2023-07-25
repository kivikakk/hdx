{
  pkgs,
  yosys,
  symbiyosys,
  hdx-config,
  hdx-versions,
}:
with pkgs.lib;
  hdx-config.python.pkgs.buildPythonPackage rec {
    name = "amaranth";

    # https://github.com/NixOS/nixpkgs/commit/7a65bb76f1db44f8af6e13d81d13f41d69fb1948
    # This fix exists for "setuptools", but not "pyproject" (which ends up
    # using pip-build-hook.sh). As a result, you can't actually import the
    # installed editable, but you might not notice because (by default) the
    # shell drops you into the Amaranth clone where "import amaranth" finds it
    # at ./. anyway.
    format = "setuptools";

    src = pkgs.fetchFromGitHub {
      owner = "amaranth-lang";
      repo = "amaranth";
      inherit (hdx-versions.amaranth) rev;
      sha256 = hdx-versions.amaranth.sha256s.${pkgs.system};
      leaveDotGit = true; # needed for setuptools-scm
    };

    nativeBuildInputs = with hdx-config.python.pkgs; [
      yosys
      pkgs.git
      setuptools
      setuptools-scm
      wheel
    ];

    buildInputs = with hdx-config.python.pkgs; [
      pyvcd
      jinja2
      yosys
    ];

    nativeCheckInputs = [
      symbiyosys
      pkgs.yices # XXX
    ];

    AMARANTH_USE_YOSYS = "system";
  }
