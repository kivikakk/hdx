{
  pkgs,
  stdenv,
  hdx-config,
  hdx-versions,
  boost,
  nextpnrArchs,
}:
with pkgs.lib; let
  src = pkgs.fetchFromGitHub {
    owner = "YosysHQ";
    repo = "nextpnr";
    inherit (hdx-versions.nextpnr) rev sha256;
  };

  mkChipdbDerivation = pkg: let
    inherit (pkg.nextpnr) archName cmakeFlags;
  in
    stdenv.mkDerivation (finalAttrs: {
      name = "nextpnr-chipdb-${archName}";
      inherit src;
      sourceRoot = "source/${archName}";

      nativeBuildInputs = [
        pkgs.cmake
        hdx-config.python
      ];

      inherit cmakeFlags;

      installPhase = ''
        cp -r chipdb $out
      '';

      passthru.nextpnr.cmakeFlags = [
        "-D${toUpper archName}_CHIPDB=${finalAttrs.finalPackage}"
      ];
    });

  chipdbs = map mkChipdbDerivation (attrValues nextpnrArchs);
in
  stdenv.mkDerivation {
    name = "nextpnr";
    inherit src;

    nativeBuildInputs =
      [pkgs.cmake] ++ chipdbs;

    buildInputs = with pkgs;
      [
        hdx-config.python
        boost
        eigen
        hdx-config.python.pkgs.apycula
      ]
      ++ attrValues nextpnrArchs;

    cmakeFlags =
      ["-DARCH=${concatStringsSep ";" hdx-config.nextpnr.archs}"]
      ++ concatMap (pkg: pkg.nextpnr.cmakeFlags) (chipdbs ++ attrValues nextpnrArchs);
  }
