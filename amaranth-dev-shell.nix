opts @ {pkgs ? import <nixpkgs> {}, ...}: let
  hdx = import ./. opts;
in
  with hdx.pkgs.lib;
    hdx.amaranth.overridePythonAttrs (prev: {
      name = "hdx-amaranth";

      src = null;

      nativeBuildInputs =
        prev.nativeBuildInputs
        ++ (filter (p: p != hdx.amaranth) (attrValues hdx.ours));

      preShellHook = ''
        export HDX_ROOT="$(pwd)"

        # setuptoolsShellHook looks for setup.py in cwd.
        cd dev/amaranth
      '';
    })
