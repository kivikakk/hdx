{
  pkgs,
  lib,
  stdenv,
  hdx-inputs,
  python,
  boost,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "yosys";
  version = "0.32dev1+g${lib.substring 0 7 hdx-inputs.yosys.rev}";

  srcs = [
    hdx-inputs.yosys
    hdx-inputs.abc
    (pkgs.writeTextDir "yosys-Makefile.conf" finalAttrs.makefileConf)
  ];

  unpackPhase = ''
    runHook preUnpack

    local -a srcsArray=( $srcs )
    cp -pr --reflink=auto -- "''${srcsArray[0]}" yosys
    cp -pr --reflink=auto -- "''${srcsArray[1]}" abc
    cp -pr --reflink=auto -- "''${srcsArray[2]}" yosys-Makefile.conf

    chmod -R u+w -- yosys

    runHook postUnpack
  '';

  sourceRoot = "yosys";

  postUnpack = ''
    cp -r abc yosys
    chmod -R u+w yosys/abc

    echo -n ${hdx-inputs.yosys.rev} >yosys/.gitcommit
    cp yosys-Makefile.conf/yosys-Makefile.conf yosys/Makefile.conf

    # Confirm abc we asked for matches yosys default.
    abcrev="$((cd yosys && make -qp 2>/dev/null || true) | awk -F' = ' '$1=="ABCREV" {print $2}')"
    echo "$abcrev" | grep -qiE '^[a-f0-9]+$'
    echo "${hdx-inputs.abc.rev}" | grep -q ^"$abcrev"
  '';

  # makeFlags with CXXFLAGS+=... ends up overriding CXXFLAGS entirely. Awkward.
  # yosys's Makefile.conf can't override CXX. Double awkward.
  makefileConfPrefix = "$(out)";
  extraMakefileConf = "";
  makefileConf =
    ''
      PREFIX=${finalAttrs.makefileConfPrefix}
      PRETTY=0
      CONFIG=clang
      # https://github.com/YosysHQ/yosys/issues/2011
      CXXFLAGS+=-xc++
    ''
    + finalAttrs.extraMakefileConf;

  nativeBuildInputs = builtins.attrValues {
    inherit
      (pkgs)
      pkg-config
      clang
      git
      bison
      flex
      ;
  };

  buildInputs = builtins.attrValues {
    inherit python boost;
    inherit
      (pkgs)
      tcl
      readline
      zlib
      libffi
      ;
  };

  enableParallelBuilding = true;
})
