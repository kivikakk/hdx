{ hdxpkgs ? import ./. {} }:

hdxpkgs.pkgs.mkShell {
  buildInputs = hdxpkgs.hdx;

  IN_NIX_SHELL_NAMED = "hdx";
}
