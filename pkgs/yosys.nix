{
  pkgs,
  lib,
  stdenv,
  hdx-inputs,
  python,
  boost,
  abc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "yosys";
  version = "0.32dev1+g${lib.substring 0 7 hdx-inputs.yosys.rev}";

  src = hdx-inputs.yosys;

  postPatch = ''
    set -ex
    env
    pwd
    ls -la
    echo -n ${hdx-inputs.yosys.rev} >.gitcommit
    cp ${pkgs.writeText "Makefile.conf" finalAttrs.makefileConf} Makefile.conf
    ls -la Makefile.conf

    # Confirm abc we asked for matches yosys default.
    abcrev="$((make -qp 2>/dev/null || true) | awk -F' = ' '$1=="ABCREV" {print $2}')"
    echo "$abcrev" | grep -qiE '^[a-f0-9]+$' || (echo 2>&1 "abcrev doesn't look right"; false)
    echo "${hdx-inputs.abc.rev}" | grep -q ^"$abcrev" || (echo 2>&1 "abcrev mismatch"; false)

    chmod u+w Makefile.conf
    echo ABCEXTERNAL=abc >> Makefile.conf
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
    inherit abc;
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
