{
  pkgs,
  yosys ? null,
  symbiyosys ? null,
  yices ? null,
  hdx-config,
  hdx-versions,
}:
with pkgs.lib; let
  python = hdx-config.python;
  pythonPkgs = python.pkgs;

  wasmtime = pythonPkgs.buildPythonPackage rec {
    pname = "wasmtime";
    version = "11.0.0";
    format = "wheel";
    src = pkgs.fetchPypi {
      inherit pname version format;
      sha256 = "2xZUHFizXVSIR3ccUoZe1QPrQqfGz4pIxAIQaXSYpSc=";
      dist = "py3";
      python = "py3";
    };

    doCheck = true;
  };

  amaranthYosys = pythonPkgs.buildPythonPackage rec {
    pname = "amaranth_yosys";
    version = "0.25.0.0.post74";
    format = "wheel";
    src = pkgs.fetchPypi {
      inherit pname version format;
      sha256 = "O9GKcE6v6uqP98QxHh+wHXgjMG3FAL2bBJGq2otPdng=";
      dist = "py3";
      python = "py3";
    };

    nativeBuildInputs = [wasmtime];

    doCheck = true;
  };
in
  pythonPkgs.buildPythonPackage rec {
    name = "amaranth";
    realVersion = "0.4.dev1+g${substring 0 7 src.rev}";

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
      inherit (hdx-versions.amaranth) rev sha256;
    };

    postUnpack = ''
      # Workaround for NixOS/nixpkgs#8567.
      pushd source
      git init
      git add -A .
      git commit -m "leaveDotGit workaround"
      popd
    '';

    nativeBuildInputs = with pythonPkgs; [
      pkgs.git
      setuptools
      setuptools-scm
      wheel
    ];

    propagatedBuildInputs = with pythonPkgs;
      [
        pyvcd
        jinja2
      ]
      ++ optional (yosys == null) amaranthYosys;

    buildInputs = [yosys];

    preBuild = ''
      export SETUPTOOLS_SCM_PRETEND_VERSION="${realVersion}"
    '';

    AMARANTH_USE_YOSYS =
      if yosys != null
      then "system"
      else "builtin";

    doCheck = yosys != null && symbiyosys != null && yices != null;

    pythonImportsCheck = ["amaranth"];

    nativeCheckInputs = [
      yosys
      symbiyosys
      yices
    ];
  }
