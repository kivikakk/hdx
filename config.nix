{pkgs}:
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

  process = opts @ {...}: let
    effective = recursiveUpdate DEFAULTS opts;
  in
    effective;
in {inherit process;}
