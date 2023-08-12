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
      # setuptoolsShellHook looks for setup.py in cwd.  Identify where amaranth
      # might be and cd to it.
      local _found=0
      for _dir in . amaranth dev/amaranth; do
        if grep -q 'name = "amaranth"' "$_dir/pyproject.toml"; then
          cd "$_dir"
          _found=1
          break
        fi
      done
      if test "$_found" -eq 0; then
        echo "ERROR: $(pwd) doesn't look like hdx or amaranth root, and no"
        echo "amaranth subdirectory was found."
        echo "'nix develop hdx#amaranth' only works when I can find amaranth,"
        echo "otherwise I can't set up correctly."
        exit 1
      fi
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
