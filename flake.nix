{
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      hdxOpts = {inherit pkgs;};
    in {
      packages.default = import ./. hdxOpts;

      formatter = pkgs.alejandra;

      devShells = {
        default = import ./. hdxOpts;
        amaranth = import ./amaranth-dev-shell.nix hdxOpts;
        yosys-amaranth = import ./yosys-amaranth-dev-shell.nix hdxOpts;
      };
    });
}
