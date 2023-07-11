{
  amaranth_dev_mode ? false,

  hdx ? import ./. {},
}:

if amaranth_dev_mode then
  hdx.amaranth.overridePythonAttrs {
    preShellHook = ''
      # pipShellHook looks for pyproject.toml in cwd.
      cd dev/amaranth
    '';

    IN_NIX_SHELL_NAMED = "hdx-amaranth";
  }
else
  hdx.pkgs.mkShell {
    buildInputs = builtins.attrValues hdx.ours;

    IN_NIX_SHELL_NAMED = "hdx";
  }
