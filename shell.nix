{ pkgs ? import <nixpkgs> {} }:

let
  hdxPkgs = pkgs.callPackage ./. {};

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    hdxPkgs.yosys
  ];

  IN_NIX_SHELL_NAMED = "hdx";
}
