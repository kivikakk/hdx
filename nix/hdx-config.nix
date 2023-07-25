{pkgs}: {nextpnr_archs ? null}:
with pkgs.lib; let
  ALL_NEXTPNR_ARCHS = ["ice40" "ecp5"];
  ALL_SYMBIYOSYS_SOLVERS = ["z3"];

  DEFAULTS = {
    inherit (pkgs) stdenv;

    python = pkgs.python311;

    amaranth.enable = true;
    yosys.enable = true;
    nextpnr = {
      enable = true;
      archs = ALL_NEXTPNR_ARCHS;
    };
    symbiyosys = {
      enable = true;
      solvers = ALL_SYMBIYOSYS_SOLVERS;
    };
  };

  mergeNonNullOptions = opts @ {...}: let
    filtered = filterAttrsRecursive (n: v: v != null) opts;
    o = recursiveUpdate DEFAULTS filtered;
  in
    assert assertMsg (o.nextpnr.enable -> o.nextpnr.archs != []) "nextpnr requires >= 1 arch";
    assert assertMsg (o.nextpnr.enable -> subtractLists ALL_NEXTPNR_ARCHS o.nextpnr.archs == []) "an invalid nextpnr arch was specified";
    assert assertMsg (o.symbiyosys.enable -> o.symbiyosys.solvers != []) "symbiyosys requires >= 1 solver";
    assert assertMsg (o.symbiyosys.enable -> subtractLists ALL_SYMBIYOSYS_SOLVERS o.symbiyosys.solvers == []) "an invalid symbiyosys solver was specified"; o;
in
  # Translate flat options.
  mergeNonNullOptions {
    nextpnr.archs = nextpnr_archs;
  }
