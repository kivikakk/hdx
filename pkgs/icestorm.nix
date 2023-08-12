{
  pkgs,
  lib,
  stdenv,
  python,
  hdx-inputs,
}:
stdenv.mkDerivation (finalAttrs: rec {
  pname = "icestorm";
  # XXX: For cursed `reasons`_, we use "-" instead of "+" here.
  # .. _reasons: https://github.com/YosysHQ/icestorm/blob/d20a5e9/icebox/Makefile#L65-L85
  version = "0.1.0dev1-g${lib.substring 0 7 src.rev}";
  src = hdx-inputs.icestorm;

  patches = [
    ../patches/icebox-Makefile.patch
  ];

  makeFlags = [
    "PREFIX=$(out)"
  ];

  nativeBuildInputs = builtins.attrValues {
    inherit python;
    inherit
      (pkgs)
      pkg-config
      libftdi
      ;
  };

  passthru.nextpnr = {
    archName = "ice40";
    cmakeFlags = [
      "-DICESTORM_INSTALL_PREFIX=${finalAttrs.finalPackage}"
    ];
  };
})
