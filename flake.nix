{
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      hdxOpts = {inherit pkgs;};
    in rec {
      packages.default = import ./. hdxOpts;

      formatter = pkgs.alejandra;

      devShells = {
        default = packages.default;
        amaranth = import ./amaranth-dev-shell.nix hdxOpts;
        yosys-amaranth = import ./yosys-amaranth-dev-shell.nix hdxOpts;
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
