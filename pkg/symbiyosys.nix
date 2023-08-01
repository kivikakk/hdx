{
  pkgs,
  stdenv,
  hdx-config,
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

    patches = [
      ../patches/sby_core.py.patch
    ];

    makeFlags = [
      "PREFIX=$(out)"
    ];

    propagatedBuildInputs = [
      hdx-config.python.pkgs.click
    ];
  }
