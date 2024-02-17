{
  python,
  jq,
  hdx,
  rainhdx,
}: let
  rainNativeBuildInputs = [
    python.pkgs.pdm-backend
    python.pkgs.python-lsp-server
    python.pkgs.python-lsp-black
    python.pkgs.pyls-isort
    python.pkgs.pylsp-rope
    python.pkgs.pylsp-mypy
    python.pkgs.pyflakes
    python.pkgs.pytest
    jq
    hdx
  ];
in
  python.pkgs.buildPythonPackage
  {
    name = "rainhdx";
    format = "pyproject";
    src = ./.;

    nativeBuildInputs = rainNativeBuildInputs;

    doCheck = true;

    pythonImportsCheck = ["rainhdx"];

    passthru = {
      inherit python;

      buildProject = opts: let
        inherit (opts) name;
      in
        python.pkgs.buildPythonPackage (opts
          // {
            format = opts.format or "pyproject";

            nativeBuildInputs =
              (opts.nativeBuildInputs or [])
              ++ rainNativeBuildInputs
              ++ [rainhdx];

            doCheck = opts.doCheck or false;

            pythonImportsCheck = opts.pythonImportsCheck or [name];

            checkPhase = ''
              set -euo pipefail

              echo "--- Unit tests."
              python -m ${name} test

              python -m ${name} internal boards | jq -r '.[]' | while read board; do
                echo "--- Building $board."
                python -m ${name} build -b "$board"
              done

              if python -m ${name} internal formal; then
                echo "--- Formal verification."
                python -m ${name} formal
              fi

              echo "--- All passed."
              env
            '';
          });
    };
  }
