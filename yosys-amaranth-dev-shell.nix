opts @ {...}: let
  hdx = import ./. {inherit opts;};
in
  with hdx.pkgs.lib;
    hdx.amaranth.overridePythonAttrs (prev: {
      name = "hdx-yosys+amaranth";

      src = null;

      nativeBuildInputs =
        remove hdx.yosys prev.nativeBuildInputs
        ++ hdx.yosys.nativeBuildInputs
        ++ subtractLists [hdx.amaranth hdx.yosys] (attrValues hdx.ours);

      buildInputs =
        remove hdx.yosys prev.buildInputs
        ++ hdx.yosys.buildInputs;

      preShellHook = ''
        cd dev/yosys
        cat >Makefile.conf <<'EOF'
        ${(hdx.yosys.overrideAttrs {makefileConfPrefix = toString ./dev/yosys;}).makefileConf}
        EOF
        cd ../..

        # setuptoolsShellHook looks for setup.py in cwd.
        cd dev/amaranth

        export PATH="${toString ./dev/yosys}:$PATH"
      '';

      postShellHook = ''
        # Start shell in ./dev.
        cd ..
      '';
    })
