{
  dev ? null,
  nextpnr_archs ? ["ice40" "ecp5"],
}: let
  hdx = (import ./. {}).override {nextpnr.archs = nextpnr_archs;};
  pkgs = hdx.pkgs;
  all = builtins.attrValues hdx.all;
in
  with pkgs.lib;
  assert assertOneOf "dev" dev ["amaranth" "amaranth+yosys" null];
    if dev == "amaranth"
    then
      hdx.amaranth.overridePythonAttrs (prev: {
        name = "hdx-amaranth";

        src = null;

        nativeBuildInputs =
          prev.nativeBuildInputs
          ++ (filter (p: p != hdx.amaranth) all);

        preShellHook = ''
          # pipShellHook looks for pyproject.toml in cwd.
          cd dev/amaranth
        '';
      })
    else if dev == "amaranth+yosys"
    then
      hdx.amaranth.overridePythonAttrs (prev: {
        name = "hdx-amaranth+yosys";

        src = null;

        nativeBuildInputs =
          prev.nativeBuildInputs
          ++ (filter (p: p != hdx.amaranth && p != hdx.yosys) all)
          ++ hdx.yosys.nativeBuildInputs;

        buildInputs =
          filter (p: p != hdx.yosys) prev.buildInputs
          ++ hdx.yosys.buildInputs;

        preShellHook = ''
          cd dev/yosys
          cat >Makefile.conf <<'EOF'
          ${(hdx.yosys.override {makefileConfPrefix = toString ./dev/yosys;}).makefileConf}
          EOF
          cd ../..

          # pipShellHook looks for pyproject.toml in cwd.
          cd dev/amaranth
        '';

        postShellHook = ''
          # Start shell in ./dev.
          cd ..
        '';

        AMARANTH_USE_YOSYS = "system";
        YOSYS = toString ./dev/yosys/yosys;
      })
    else
      pkgs.mkShell {
        name = "hdx";
        buildInputs = all;
      }
