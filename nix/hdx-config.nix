{pkgs, ...}: let
  inherit (pkgs) lib;

  ALL_NEXTPNR_ARCHS = ["generic" "ice40" "ecp5"];
  ALL_SYMBIYOSYS_SOLVERS = ["yices" "z3"];

  DEFAULTS = {
    inherit (pkgs) stdenv;

    python = import ./python.nix {python = pkgs.python311;};

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

    leaveDotGitWorkaround = ''
      # Workaround for NixOS/nixpkgs#8567.
      pushd source
      git init
      git config user.email charlotte@example.com
      git config user.name Charlotte
      git add -A .
      git commit -m "leaveDotGit workaround"
      popd
    '';
  };

  opts = DEFAULTS;
in
  assert lib.assertMsg (opts.nextpnr.enable -> opts.nextpnr.archs != []) "nextpnr requires >= 1 arch";
  assert lib.assertMsg (opts.nextpnr.enable -> lib.subtractLists ALL_NEXTPNR_ARCHS opts.nextpnr.archs == []) "an invalid nextpnr arch was specified";
  assert lib.assertMsg (opts.symbiyosys.enable -> opts.symbiyosys.solvers != []) "symbiyosys requires >= 1 solver";
  assert lib.assertMsg (opts.symbiyosys.enable -> lib.subtractLists ALL_SYMBIYOSYS_SOLVERS opts.symbiyosys.solvers == []) "an invalid symbiyosys solver was specified";
  # :)
    opts
