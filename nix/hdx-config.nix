{
  pkgs,
  nextpnr_archs ? null,
}:
with pkgs.lib; let
  DEFAULTS = {
    inherit (pkgs) stdenv;

    python = pkgs.python311;

    amaranth.enable = true;
    yosys.enable = true;
    nextpnr = {
      enable = true;
      archs = ["ice40" "ecp5"];
    };
    symbiyosys = {
      enable = true;
      solvers = ["z3"];
    };
  };

  mergeNonNullOptions = opts @ {...}: let
    filtered = filterAttrsRecursive (n: v: v != null) opts;
    effective = recursiveUpdate DEFAULTS filtered;
  in
    effective;
in
  mergeNonNullOptions {
    nextpnr.archs = nextpnr_archs;
  }
