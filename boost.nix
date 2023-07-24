{
  pkgs,
  hdx-config,
}:
pkgs.boost.override {
  inherit (hdx-config) stdenv python;
  enablePython = true;
}
