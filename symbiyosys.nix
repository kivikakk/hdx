{
  pkgs,
  stdenv,
  python,
  git,
  hdx-versions,
}:
with pkgs.lib;
  stdenv.mkDerivation {
    name = "symbiyosys";

    src = pkgs.fetchFromGitHub {
      owner = "YosysHQ";
      repo = "sby";
      inherit (hdx-versions.symbiyosys) rev sha256;
    };

    makeFlags = [
      "PREFIX=$(out)"
    ];

    propagatedBuildInputs = [
      python.pkgs.click
    ];
  }
