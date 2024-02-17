{
  stdenv,
  verilog,
  python,
  gdb,
  lldb,
  jq,
  lib,
  hdx,
  hdxSetupHook,
  rainhdx,
  amaranth,
  yosys,
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
        self = python.pkgs.buildPythonPackage (opts
          // {
            format = opts.format or "pyproject";

            nativeBuildInputs =
              (opts.nativeBuildInputs or [])
              ++ rainNativeBuildInputs
              ++ [
                rainhdx
                hdxSetupHook
              ];

            doCheck = opts.doCheck or false;

            pythonImportsCheck = opts.pythonImportsCheck or [name];

            passthru.devShells = {
              default = self;

              yosys = self.overridePythonAttrs (prev: {
                # TODO: deduplicate with ../flake.nix's devShells.amaranth-yosys.
                name = "${name}+yosys";
                src = null;

                nativeBuildInputs =
                  prev.nativeBuildInputs
                  ++ yosys.nativeBuildInputs
                  ++ [
                    (
                      if stdenv.isDarwin
                      then lldb
                      else gdb
                    )
                    verilog
                  ];

                buildInputs =
                  (prev.buildInputs or [])
                  ++ yosys.buildInputs;

                preShellHook =
                  lib.replaceStrings ["@Makefile.conf.hdx@"] [
                    (yosys.overrideAttrs {
                      makefileConfPrefix = "$(HDX_OUT)";
                      extraMakefileConf = ''
                        ENABLE_DEBUG=1
                        STRIP=echo hdx: Not doing this: strip
                      '';
                    })
                    .makefileConf
                  ]
                  (builtins.readFile
                    ../yosys-shell-hook.sh);

                inherit (amaranth) AMARANTH_USE_YOSYS;
              });
            };

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
      in
        self;
    };
  }
