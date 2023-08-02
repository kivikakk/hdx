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

    buildInputs = [
      pkgs.coreutils
    ];

    postPatch = ''
      substituteInPlace sbysrc/sby_core.py --replace "/usr/bin/env" "${pkgs.coreutils}/bin/env"
    '';

    makeFlags = [
      "PREFIX=$(out)"
    ];

    propagatedBuildInputs = [
      hdx-config.python.pkgs.click
    ];
  }
