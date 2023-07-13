{
  pkgs,

  icestorm,
  trellis,

  nextpnr_archs,
}:

with pkgs.lib;

let
  ARCH_MAPPINGS = {
    ice40 = icestorm;
    ecp5 = trellis;
  };

  arch_enabled =
    flip elem nextpnr_archs;

  enabled =
    flip elem enabled_pkgs;

  enabled_pkgs =
    assert all
      (a: assertOneOf "each nextpnr arch" a (attrNames ARCH_MAPPINGS))
      nextpnr_archs;
    map (flip getAttr ARCH_MAPPINGS) nextpnr_archs;

in

assert assertMsg (enabled_pkgs != []) "nextpnr needs at least one arch";

{
  inherit
    arch_enabled
    enabled
    enabled_pkgs
  ;
}
