{
  pkgs,
  stdenv,
  hdx-config,
  hdx-versions,
}:
with pkgs.lib;
  stdenv.mkDerivation {
    name = "yices";

    src = pkgs.fetchFromGitHub {
      owner = "SRI-CSL";
      repo = "yices2";
      inherit (hdx-versions.yices) rev sha256;
    };

    nativeBuildInputs = with pkgs; [
      autoreconfHook
      gperf
      gmp
    ];

    enableParallelBuilding = true;
  }
