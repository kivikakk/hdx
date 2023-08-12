{
  inputs = {
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };

    amaranth = {
      url = github:amaranth-lang/amaranth;
      flake = false;
    };
    amaranth-boards = {
      url = github:amaranth-lang/amaranth-boards;
      flake = false;
    };
    yosys = {
      url = github:YosysHQ/yosys;
      flake = false;
    };
    abc = {
      url = github:YosysHQ/abc?rev=bb64142b07794ee685494564471e67365a093710;
      flake = false;
    };
    nextpnr = {
      url = github:YosysHQ/nextpnr?rev=54b2045726fc3fe77857c05c81a5ab77e98ba851;
      flake = false;
    };
    icestorm = {
      url = github:YosysHQ/icestorm?rev=d20a5e9001f46262bf0cef220f1a6943946e421d;
      flake = false;
    };
    trellis = {
      #type = "git";
      url = git+https://github.com/YosysHQ/prjtrellis?rev=e830a28077e1a789d32e75841312120ae624c8d6&submodules=1;
      flake = false;
    };

    symbiyosys = {
      url = github:YosysHQ/sby?rev=cf0a761a3a0ba2e38258ff72f93505c85834dd16;
      flake = false;
    };
    yices = {
      url = github:SRI-CSL/yices2?rev=5a3e3f0fabf7d588c5adf1f791b26a590eac547f;
      flake = false;
    };
    z3 = {
      url = github:Z3Prover/z3?ref=z3-4.12.2;
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      hdx = import ./hdx.nix {
        inherit system pkgs;
        hdx-inputs = inputs;
      };
    in rec {
      packages.default = hdx;

      formatter = pkgs.alejandra;

      devShells = {
        default = hdx;
        amaranth = import ./amaranth-dev-shell.nix {inherit hdx;};
        yosys-amaranth = import ./yosys-amaranth-dev-shell.nix {inherit hdx;};
      };

      checks = {
        ensure-ecppack-call-works =
          pkgs.runCommand "ensure-ecppack-call-works" {
            nativeBuildInputs = [packages.default];
          } ''
            ecppack ${packages.default.trellis}/share/trellis/misc/basecfgs/empty_lfe5u-85f.config /dev/null
            touch $out
          '';
      };
    });
}
