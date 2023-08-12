{hdx ? null}:
if hdx != null
then let
  inherit (hdx) system pkgs lib;
  debuggerPkg =
    if builtins.match ".*-darwin" system != null
    then pkgs.lldb
    else pkgs.gdb;
in
  hdx.amaranth.overridePythonAttrs (prev: {
    name = "hdx-yosys+amaranth";

    src = null;

    nativeBuildInputs =
      prev.nativeBuildInputs
      ++ hdx.yosys.nativeBuildInputs
      ++ lib.subtractLists [hdx.amaranth hdx.yosys] (builtins.attrValues hdx.ours)
      ++ [
        debuggerPkg
        pkgs.verilog
      ]; # TODO

    buildInputs =
      lib.remove hdx.yosys prev.buildInputs
      ++ hdx.yosys.buildInputs;

    preShellHook = ''
      if ! test -d dev/yosys -a -d dev/amaranth; then
        echo "ERROR: $(pwd) doesn't look like hdx root?"
        echo "(no 'dev/yosys', 'dev/amaranth' found)"
        echo "'nix develop hdx#yosys-amaranth' only works when executed with hdx-like cwd,"
        echo "otherwise I can't set up correctly."
        exit 1
      fi

      export HDX_ROOT="$(pwd)"

      cd dev/yosys
      cat >Makefile.conf <<'EOF'
      ${(hdx.yosys.overrideAttrs {
          makefileConfPrefix = "$(HDX_ROOT)/dev/out";
          extraMakefileConf = ''
            ENABLE_DEBUG=1
            STRIP=echo Not doing this: strip
          '';
        })
        .makefileConf}
      EOF
      cd ../..

      # setuptoolsShellHook looks for setup.py in cwd.
      cd dev/amaranth

      export PATH="$HDX_ROOT/dev/out/bin:$PATH"
    '';

    postShellHook = ''
      # Start shell back at root, to avoid moving the user.
      cd $HDX_ROOT
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
  .yosys-amaranth
