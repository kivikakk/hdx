{ hdx ? import ./. {} }:

hdx.pkgs.mkShell {
  buildInputs = hdx.all;

  IN_NIX_SHELL_NAMED = "hdx";
}
