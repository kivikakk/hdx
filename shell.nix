{
  amaranth_dev_mode ? false,

  hdx ? import ./. {},
}:

let
  ours = builtins.attrValues hdx.ours;

in
if amaranth_dev_mode then
  hdx.amaranth.overridePythonAttrs (prev: {
    src = null;

    nativeBuildInputs =
      prev.nativeBuildInputs ++
      (builtins.filter (p: p != hdx.amaranth) ours);

    preShellHook = ''
      # pipShellHook looks for pyproject.toml in cwd.
      cd dev/amaranth
    '';

    IN_NIX_SHELL_NAMED = "hdx-amaranth";
  })
else
  hdx.pkgs.mkShell {
    buildInputs = ours;

    IN_NIX_SHELL_NAMED = "hdx";
  }
