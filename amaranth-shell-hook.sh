amaranthPreShellHook() {
    set -e
    export HDX_START="$(pwd)"

    local _found=0 _dir
    for _dir in . amaranth; do
        if grep -q 'name = "amaranth"' "$_dir/pyproject.toml" 2>/dev/null; then
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
}

amaranthPreShellHook
