opts @ {pkgs ? import <nixpkgs> {}, ...}: let
  hdx = import ./. opts;
in
  with hdx.pkgs.lib;
    hdx.amaranth.overridePythonAttrs (prev: {
      name = "hdx-yosys+amaranth";

      src = null;

      nativeBuildInputs =
        prev.nativeBuildInputs
        ++ hdx.yosys.nativeBuildInputs
        ++ subtractLists [hdx.amaranth hdx.yosys] (attrValues hdx.ours);

      buildInputs =
        remove hdx.yosys prev.buildInputs
        ++ hdx.yosys.buildInputs;

      preShellHook = ''
        export HDX_ROOT="$(pwd)"

        cd dev/yosys
        cat >Makefile.conf <<'EOF'
        ${(hdx.yosys.overrideAttrs {makefileConfPrefix = "$(HDX_ROOT)/dev/out";}).makefileConf}
        EOF
        cd ../..

        # setuptoolsShellHook looks for setup.py in cwd.
        cd dev/amaranth

        export PATH="$HDX_ROOT/dev/out/bin:$PATH"
      '';

      postShellHook = ''
        # Start shell in ./dev.
        cd ..
      '';

      doCheck = false; # so yosys doesn't get pulled in for Amaranth test.
    })
