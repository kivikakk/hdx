{hdx ? null}:
if hdx != null
then let
  inherit (hdx) lib;
in
  hdx.amaranth.overridePythonAttrs (prev: {
    name = "hdx-amaranth";

    src = null;

    nativeBuildInputs =
      prev.nativeBuildInputs
      ++ (lib.filter (p: p != hdx.amaranth) (builtins.attrValues hdx.ours));

    preShellHook = ''
      ${hdx.devCheckHook ["dev/amaranth"] "nix develop hdx#amaranth"}
      export HDX_ROOT="$(pwd)"

      # setuptoolsShellHook looks for setup.py in cwd.
      cd dev/amaranth
    '';

    doCheck = false;
  })
else
  (
    import
    (
      let
        lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      in
        fetchTarball {
          url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
          sha256 = lock.nodes.flake-compat.locked.narHash;
        }
    )
    {src = ./.;}
  )
  .defaultNix
  .devShells
  .${builtins.currentSystem}
  .amaranth
