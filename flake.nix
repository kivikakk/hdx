{
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages.default = (import ./.) {pkgs = nixpkgs.legacyPackages.${system};};
    });
}
