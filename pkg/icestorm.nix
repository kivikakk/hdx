{
  pkgs,
  stdenv,
  hdx-config,
  hdx-versions,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "icestorm";

  src = pkgs.fetchFromGitHub {
    owner = "YosysHQ";
    repo = "icestorm";
    inherit (hdx-versions.icestorm) rev sha256;
  };

  patches = [
    ../patches/icebox-Makefile.patch
  ];

  makeFlags = [
    "PREFIX=$(out)"
  ];

  nativeBuildInputs = with pkgs; [
    pkg-config
    hdx-config.python
    libftdi
  ];

  passthru.nextpnr = {
    archName = "ice40";
    cmakeFlags = [
      "-DICESTORM_INSTALL_PREFIX=${finalAttrs.finalPackage}"
    ];
  };
})
