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
      set -e
      export HDX_START="$(pwd)"

      # setuptoolsShellHook looks for setup.py in cwd.  Identify where amaranth
      # might be and cd to it.
      local _found=0 _dir
      for _dir in . amaranth; do
        if grep -q 'name = "amaranth"' "$_dir/pyproject.toml"; then
          cd "$_dir"
          _found=1
          break
        fi
      done
      if test "$_found" -eq 0; then
        echo "hdx: ERROR: '$(pwd)' doesn't look like Amaranth root, and no"
        echo "hdx: 'amaranth' subdirectory was found."
        echo "hdx: 'nix develop hdx#amaranth' only works when I can find Amaranth,"
        echo "hdx: otherwise I can't set up correctly."
        exit 1
      fi
    '';

    postShellHook = ''
      # Start shell back where we came from.
      cd $HDX_START
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
