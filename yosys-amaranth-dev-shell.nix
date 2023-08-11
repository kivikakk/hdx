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
      ${hdx.devCheckHook ["dev/yosys" "dev/amaranth"] "nix develop hdx#yosys-amaranth"}
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
      # Start shell in ./dev.
      cd ..
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
