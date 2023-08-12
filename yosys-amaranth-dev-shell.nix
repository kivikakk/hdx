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
      export HDX_DEV_OUTDIR="hdx-out"

      local _found=0 _hdxenough=0 _dir
      for _dir in . dev; do
        if test -d "$_dir/yosys" -a -d "$_dir/amaranth"; then
          if test "$_dir" = "dev"; then
            _hdxenough=1
            HDX_DEV_OUTDIR="out"
          fi
          cd "$_dir"
          export HDX_DEV_ROOT="$(pwd)"
          _found=1
          break
        fi
      done

      if test "$_found" -eq 0; then
        echo "ERROR: '$(pwd)' doesn't contain 'yosys' and 'amaranth' directories, either"
        echo "directly or within a 'dev' directory."
        echo "'nix develop hdx#yosys-amaranth' only works when executed with hdx-like cwd,"
        echo "otherwise I can't set up correctly."
        exit 1
      fi

      if ! test -d "$HDX_DEV_OUTDIR"; then
        if test "$_hdxenough" -eq 0; then
          echo "Running \`mkdir $HDX_DEV_OUTDIR\` for Yosys install outputs."
        fi
        mkdir "$HDX_DEV_OUTDIR"
      fi

      cd yosys
      cat >Makefile.conf.hdx <<'EOF'
      ${(hdx.yosys.overrideAttrs {
          makefileConfPrefix = "$(HDX_DEV_ROOT)/$(HDX_DEV_OUTDIR)";
          extraMakefileConf = ''
            ENABLE_DEBUG=1
            STRIP=echo Not doing this: strip
          '';
        })
        .makefileConf}
      EOF
      if test "$_hdxenough" -eq 0 -a -f Makefile.conf; then
        if ! diff --color -u Makefile.conf Makefile.conf.hdx; then
          echo
          echo "ERROR: '$(pwd)/Makefile.conf' exists and differs from what I want to install."
          echo "Not doing any more.  '$(pwd)/Makefile.conf.hdx' is left in place."
          exit 1
        fi
      fi
      mv Makefile.conf.hdx Makefile.conf
      export PATH="$HDX_ROOT/$HDX_DEV_OUTDIR/bin:$PATH"
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
