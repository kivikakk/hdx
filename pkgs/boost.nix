{
  pkgs,
  stdenv,
  python,
}:
pkgs.boost.override {
  inherit stdenv python;
  enablePython = true;
}
