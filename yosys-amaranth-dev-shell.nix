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
        pkgs.verilog # TODO
      ];

    buildInputs =
      lib.remove hdx.yosys prev.buildInputs
      ++ hdx.yosys.buildInputs;

    preShellHook = ''
      export HDX_START="$(pwd)"

      local _found=0 _dir
      for _dir in .; do
        if test -d "$_dir/yosys" -a -d "$_dir/amaranth"; then
          cd "$_dir"
          export HDX_OUT="$(pwd)/hdx-out"
          _found=1
          break
        fi
      done

      if test "$_found" -eq 0; then
        echo "ERROR: '$(pwd)' doesn't contain 'yosys' and 'amaranth' directories."
        echo "'nix develop hdx#yosys-amaranth' only works when executed with cwd"
        echo "containing these, otherwise I can't set up correctly."
        exit 1
      fi

      if ! test -d "$HDX_OUT"; then
        echo "Running \`mkdir $HDX_OUT\` for Yosys install outputs."
        mkdir "$HDX_OUT"
      fi

      cd yosys
      cat >Makefile.conf.hdx <<'EOF'
      ${(hdx.yosys.overrideAttrs {
          makefileConfPrefix = "$(HDX_OUT)";
          extraMakefileConf = ''
            ENABLE_DEBUG=1
            STRIP=echo Not doing this: strip
          '';
        })
        .makefileConf}
      EOF
      if test -f Makefile.conf; then
        if ! diff --color -u Makefile.conf Makefile.conf.hdx; then
          echo
          echo "ERROR: '$(pwd)/Makefile.conf' exists and differs from what I want to install."
          echo "Not doing any more.  '$(pwd)/Makefile.conf.hdx' is left in place."
          exit 1
        fi
      fi
      mv Makefile.conf.hdx Makefile.conf
      export PATH="$HDX_OUT/bin:$PATH"
      cd ..

      # setuptoolsShellHook looks for setup.py in cwd, so finish in amaranth/.
      cd amaranth
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
  .yosys-amaranth
