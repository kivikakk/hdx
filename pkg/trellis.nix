{
  pkgs,
  stdenv,
  hdx-config,
  hdx-versions,
  boost,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "trellis";

  src = pkgs.fetchFromGitHub {
    name = "prjtrellis";
    owner = "YosysHQ";
    repo = "prjtrellis";
    inherit (hdx-versions.trellis) rev sha256;
    fetchSubmodules = true;
  };

  sourceRoot = "prjtrellis/libtrellis";

  nativeBuildInputs = with pkgs; [
    cmake
    hdx-config.python
    libftdi
  ];

  buildInputs = [boost];

  cmakeFlags = [
    "-DCMAKE_INSTALL_DATADIR=${placeholder "out"}/share"
  ];

  postInstall = pkgs.lib.optionalString stdenv.isDarwin ''
    for f in $out/bin/* ; do
      install_name_tool -change "$out/lib/libtrellis.dylib" "$out/lib/trellis/libtrellis.dylib" "$f"
    done
  '';

  postInstallCheck = ''
    $out/bin/ecppack /dev/null
  '';

  passthru.nextpnr = {
    archName = "ecp5";
    cmakeFlags = [
      "-DTRELLIS_INSTALL_PREFIX=${finalAttrs.finalPackage}"
      "-DTRELLIS_LIBDIR=${finalAttrs.finalPackage}/lib/trellis"
    ];
  };
})
