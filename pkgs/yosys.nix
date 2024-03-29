{
  writeText,
  pkg-config,
  clang,
  git,
  bison,
  flex,
  boost,
  tcl,
  readline,
  zlib,
  libffi,
  stdenv,
  lib,
  hdxInputs,
  python,
  abc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "yosys";
  version = "0.32dev1+g${lib.substring 0 7 hdxInputs.yosys.rev}";

  src = hdxInputs.yosys;

  postPatch = ''
    ls -la
    echo -n ${hdxInputs.yosys.rev} >.gitcommit
    cp ${writeText "Makefile.conf" finalAttrs.makefileConf} Makefile.conf
    ls -la Makefile.conf

    # Confirm abc we asked for matches yosys default.
    abcrev="$((make -qp 2>/dev/null || true) | awk -F' = ' '$1=="ABCREV" {print $2}')"
    echo "$abcrev" | grep -qiE '^[a-f0-9]+$' || (echo 2>&1 "abcrev doesn't look right"; false)
    echo "${hdxInputs.abc.rev}" | grep -q ^"$abcrev" || (echo 2>&1 "abcrev mismatch"; false)
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
      ABCEXTERNAL=abc
    ''
    + finalAttrs.extraMakefileConf;

  nativeBuildInputs = [
    abc
    pkg-config
    clang
    git
    bison
    flex
  ];

  buildInputs = [
    python
    boost
    tcl
    readline
    zlib
    libffi
  ];

  enableParallelBuilding = true;
})
