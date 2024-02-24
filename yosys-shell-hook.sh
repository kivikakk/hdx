yosysShellHook() {
    set -e
    export HDX_START="$(pwd)"

    local _found=0 _dir
    for _dir in . ..; do
      if test -d "$_dir/yosys"; then
        cd "$_dir"
        _found=1
        break
      fi
    done

    if test "$_found" -eq 0; then
      echo "hdx: ERROR: neither '$(pwd)' nor its parent contains a 'yosys' directory."
      echo "hdx: rainhdx's 'yosys' project devShell only works when executed with Yosys"
      echo "hdx: in one of these places, otherwise I can't set up correctly."
      exit 1
    fi

    cd yosys

    export HDX_OUT="$(pwd)/hdx-out"
    if ! test -d "$HDX_OUT"; then
      echo "hdx: Running \`mkdir $HDX_OUT\` for Yosys install outputs."
      mkdir "$HDX_OUT"
    fi
    export PATH="$HDX_OUT/bin:$PATH"

    # This ensures e.g. sby uses the right version, and not the one in its closure.
    export YOSYS="$HDX_OUT/bin/yosys"

    # Install a Makefile.conf that will compile Yosys correctly (and for debug),
    # and install it where we expect.  Ensure we don't overwrite a user's own one.
    cat >Makefile.conf.hdx <<'EOF'
@Makefile.conf.hdx@
EOF
    if test -f Makefile.conf; then
      if ! diff --color -u Makefile.conf Makefile.conf.hdx; then
        echo
        echo "hdx: ERROR: '$(pwd)/Makefile.conf' exists and differs from what I want to install."
        echo "hdx: Not doing any more.  '$(pwd)/Makefile.conf.hdx' is left in place."
        exit 1
      fi
    fi
    mv Makefile.conf.hdx Makefile.conf

    # Append the created output directory to .git/info/exclude so it doesn't
    # make their Yosys checkout look dirty.
    if ! grep -q hdx-out .git/info/exclude; then
      echo "hdx: Appending '/hdx-out' to '$(pwd)/.git/info/exclude'."
      echo /hdx-out >> .git/info/exclude
    fi

    # Return to the project so the regular Python hook runs.
    cd "$HDX_START"
}

yosysShellHook
