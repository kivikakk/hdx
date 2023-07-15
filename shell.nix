{
  amaranth_dev_mode ? false,
  nextpnr_archs ? ["ice40" "ecp5"],
}: let
  hdx = (import ./. {}).override {nextpnr.archs = nextpnr_archs;};
  all = builtins.attrValues hdx.all;
in
  if amaranth_dev_mode
  then
    hdx.amaranth.overridePythonAttrs ({nativeBuildInputs, ...}: {
      src = null;

      nativeBuildInputs =
        nativeBuildInputs
        ++ (builtins.filter (p: p != hdx.amaranth) all);

      preShellHook = ''
        # pipShellHook looks for pyproject.toml in cwd.
        cd dev/amaranth
      '';

      # IN_NIX_SHELL_NAMED = "hdx-amaranth";
    })
  else
    hdx.pkgs.mkShell {
      name = "hdx";
      buildInputs = all;
    }
