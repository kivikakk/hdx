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
        ++ subtractLists [hdx.amaranth hdx.yosys] (attrValues hdx.ours)
        ++ [pkgs.gdb pkgs.verilog]; # TODO

      buildInputs =
        remove hdx.yosys prev.buildInputs
        ++ hdx.yosys.buildInputs;

      preShellHook = ''
        ${hdx.devCheckHook ["dev/yosys" "dev/amaranth"] "nix develop hdx#yosys-amaranth"}
        export HDX_ROOT="$(pwd)"

        cd dev/yosys
        cat >Makefile.conf <<'EOF'
        ${(hdx.yosys.overrideAttrs {
          makefileConfPrefix = "$(HDX_ROOT)/dev/out";
          extraMakefileConf = ''
            ENABLE_DEBUG=1
            STRIP=echo Not doing this: strip
          '';
        }).makefileConf}
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

      doCheck = false;
    })
