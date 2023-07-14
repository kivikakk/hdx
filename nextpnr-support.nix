{
  pkgs,

  icestorm,
  trellis,

  hdx-config,
}:

with pkgs.lib;

let
  inherit (hdx-config.nextpnr) archs;

  ARCH_MAPPINGS = {
    ice40 = icestorm;
    ecp5 = trellis;
  };

  arch_enabled =
    flip elem archs;

  enabled =
    flip elem enabled_pkgs;

  enabled_pkgs =
    assert all
      (a: assertOneOf "each nextpnr arch" a (attrNames ARCH_MAPPINGS))
      archs;
    map (flip getAttr ARCH_MAPPINGS) archs;

in

assert assertMsg (enabled_pkgs != []) "nextpnr needs at least one arch";

{
  inherit
    arch_enabled
    enabled
    enabled_pkgs
  ;
}
