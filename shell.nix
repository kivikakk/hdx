{
  dev ? null,
  nextpnr_archs ? ["ice40" "ecp5"],
}: let
  hdx = (import ./. {}).override {nextpnr.archs = nextpnr_archs;};
  pkgs = hdx.pkgs;
  all = builtins.attrValues hdx.all;
in
  with pkgs.lib;
  assert assertOneOf "dev" dev ["amaranth" "yosys" null];
    if dev == "amaranth"
    then
      hdx.amaranth.overridePythonAttrs ({nativeBuildInputs, ...}: {
        name = "hdx-amaranth";

        src = null;

        nativeBuildInputs =
          nativeBuildInputs
          ++ (filter (p: p != hdx.amaranth) all);

        preShellHook = ''
          # pipShellHook looks for pyproject.toml in cwd.
          cd dev/amaranth
        '';
      })
    else if dev == "yosys"
    then
      pkgs.mkShell {
        name = "hdx-yosys";

        # buildInputs vs packages here?
        buildInputs = filter (p: p != hdx.amaranth && p != hdx.yosys) all;

        inputsFrom = [hdx.yosys];

        shellHook = ''
          cd dev/yosys
          cat >Makefile.conf <<'EOF'
        '' + hdx.yosys.makefileConf + "\nEOF" + ''
        '';
      }
    else
      pkgs.mkShell {
        name = "hdx";
        buildInputs = all;
      }
