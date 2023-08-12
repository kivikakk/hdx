{
  pkgs,
  lib,
  stdenv,
  hdx-config,
  hdx-inputs,
  python,
  boost,
  nextpnrArchs,
}: let
  src = hdx-inputs.nextpnr;
  version = "0.6dev1+g${lib.substring 0 7 src.rev}";

  mkChipdbDerivation = pkg: let
    inherit (pkg.nextpnr) archName cmakeFlags;
  in
    stdenv.mkDerivation (finalAttrs: {
      pname = "nextpnr-chipdb-${archName}";
      inherit version src;
      sourceRoot = "source/${archName}";

      nativeBuildInputs = builtins.attrValues {
        inherit python;
        inherit (pkgs) cmake;
      };

      inherit cmakeFlags;

      installPhase = ''
        cp -r chipdb $out
      '';

      passthru.nextpnr.cmakeFlags = [
        "-D${lib.toUpper archName}_CHIPDB=${finalAttrs.finalPackage}"
      ];
    });

  chipdbs = map mkChipdbDerivation (builtins.attrValues nextpnrArchs);
in
  stdenv.mkDerivation {
    pname = "nextpnr";
    inherit version src;

    nativeBuildInputs =
      [pkgs.cmake] ++ chipdbs;

    buildInputs = builtins.attrValues (
      {
        inherit
          python
          boost
          ;
        inherit (pkgs) eigen;
        inherit (python.pkgs) apycula;
      }
      // nextpnrArchs
    );

    cmakeFlags =
      ["-DARCH=${lib.concatStringsSep ";" hdx-config.nextpnr.archs}"]
      ++ lib.concatMap (pkg: pkg.nextpnr.cmakeFlags) (chipdbs ++ builtins.attrValues nextpnrArchs);
  }
