{pkgs}: {nextpnr_archs ? null}:
with pkgs.lib; let
  DEFAULTS = {
    inherit (pkgs) stdenv;

    python = pkgs.python311;

    amaranth.enable = true; # TODO
    yosys.enable = true; # TODO
    nextpnr = {
      enable = true; # TODO
      archs = ["ice40" "ecp5"];
    };
    symbiyosys = {
      enable = true; # TODO
      solvers = ["z3"]; # TODO
    };
  };

  mergeNonNullOptions = opts @ {...}: let
    filtered = filterAttrsRecursive (n: v: v != null) opts;
    effective = recursiveUpdate DEFAULTS filtered;
  in
    effective;
in
  # Translate flat options.
  mergeNonNullOptions {
    nextpnr.archs = nextpnr_archs;
  }
