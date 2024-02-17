# This is actually verbatim setuptoolsShellHook, except:
#
# (a) we do not look for setup.py, we run always (pyproject.toml is
#     present; we don't bother checking);
#
# (b) we propagate "python.pkgs.editables" into its closure, which PDM's
#     "editables" editable build format relies upon:
#     https://pdm-backend.fming.dev/build_config/#editables.
#     We don't use it directly, but PDM depends on the library anyway.

hdxSetupHook() {
  echo "Executing hdxSetupHook"
  set -e
  runHook preShellHook

  tmp_path=$(mktemp -d)
  export PATH="$tmp_path/bin:$PATH"
  export PYTHONPATH="$tmp_path/@pythonSitePackages@:$PYTHONPATH"
  mkdir -p "$tmp_path/@pythonSitePackages@"
  eval "@pythonInterpreter@ -m pip install -e . --prefix $tmp_path \
    --no-build-isolation >&2"
  # Process pth file installed in tmp path. This allows one to
  # actually import the editable installation. Note site.addsitedir
  # appends, not prepends, new paths. Hence, it is not possible to override
  # an existing installation of the package.
  # https://github.com/pypa/setuptools/issues/2612
  export NIX_PYTHONPATH="$tmp_path/@pythonSitePackages@:${NIX_PYTHONPATH-}"

  runHook postShellHook
  echo "Finished executing hdxSetupHook"
}

shellHook=hdxSetupHook
