{ pkgs ? import <nixpkgs> {} }:

let
  hdx = pkgs.callPackage ./. {};

in
pkgs.mkShell {
  buildInputs = hdx.all;

  IN_NIX_SHELL_NAMED = "hdx";
}
