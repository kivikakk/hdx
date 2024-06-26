{
  git,
  fetchPypi,
  lib,
  hdxInputs,
  python,
  yosys,
  symbiyosys,
  yices,
}: let
  wasmtime = python.pkgs.buildPythonPackage rec {
    pname = "wasmtime";
    version = "11.0.0";
    format = "wheel";
    src = fetchPypi {
      inherit pname version format;
      sha256 = "2xZUHFizXVSIR3ccUoZe1QPrQqfGz4pIxAIQaXSYpSc=";
      dist = "py3";
      python = "py3";
    };

    doCheck = true;
  };

  amaranthYosys = python.pkgs.buildPythonPackage rec {
    pname = "amaranth_yosys";
    version = "0.25.0.0.post74";
    format = "wheel";
    src = fetchPypi {
      inherit pname version format;
      sha256 = "O9GKcE6v6uqP98QxHh+wHXgjMG3FAL2bBJGq2otPdng=";
      dist = "py3";
      python = "py3";
    };

    nativeBuildInputs = [wasmtime];

    doCheck = true;
  };

  pdmBackend =  python.pkgs.buildPythonPackage rec {
    pname = "pdm_backend";
    version = "2.2.1";
    format = "wheel";
    src = fetchPypi {
      inherit pname version format;
      sha256 = "oz+Clcp9gSDviHGLm2hijozKQQJoa+DweDv1hEOZ8pY=";
      dist = "py3";
      python = "py3";
    };

    nativeBuildInputs = [];

    doCheck = true;
  };
in
  python.pkgs.buildPythonPackage rec {
    pname = "amaranth";
    version = "0.4.4dev1+g${lib.substring 0 7 src.rev}";
    format = "pyproject";
    src = hdxInputs.amaranth;

    nativeBuildInputs = [
      git
      pdmBackend
    ];

    propagatedBuildInputs =
      [
        python.pkgs.pyvcd
        python.pkgs.jinja2
      ]
      ++ lib.optional (yosys == null) amaranthYosys;

    buildInputs = [yosys];

    PDM_BUILD_SCM_VERSION = version;
    AMARANTH_USE_YOSYS = "system";

    doCheck = true;

    pythonImportsCheck = ["amaranth"];

    nativeCheckInputs = [
      yosys
      symbiyosys
      yices
    ];

    meta = {
      description = "Amaranth hardware definition language";
    };
  }
