{
  pkgs,
  stdenv,
  hdx-config,
  hdx-versions,
  boost,
}:
stdenv.mkDerivation rec {
  name = "yosys";

  srcs = [
    (pkgs.fetchFromGitHub {
      name = "yosys";
      owner = "YosysHQ";
      repo = "yosys";
      inherit (hdx-versions.yosys) rev sha256;
    })
    (pkgs.fetchFromGitHub {
      name = "abc";
      owner = "YosysHQ";
      repo = "abc";
      inherit (hdx-versions.abc) rev sha256;
    })
  ];

  sourceRoot = "yosys";

  postUnpack = ''
    cp -r abc yosys
    chmod -R u+w yosys/abc
    echo -n ${hdx-versions.yosys.rev} >yosys/.gitcommit

    # Confirm abc we asked for matches yosys default.
    abcrev="$((make -qpf yosys/Makefile 2>/dev/null || true) | awk -F' = ' '$1=="ABCREV" {print $2}')"
    echo "$abcrev" | grep -qiE '^[a-f0-9]+$'
    echo "${hdx-versions.abc.rev}" | grep -q ^"$abcrev"
  '';

  # makeFlags with CXXFLAGS+=... ends up overriding CXXFLAGS entirely. Awkward.
  makefileConf = ''
    PREFIX=$(out)
    PRETTY=0
    CONFIG=clang
    # https://github.com/YosysHQ/yosys/issues/2011
    CXXFLAGS+=-xc++
  '';

  preBuild = ''
    cat >Makefile.conf <<'EOF'
  '' + makefileConf + "\nEOF" + ''
  '';

  nativeBuildInputs = with pkgs; [
    pkg-config
    git
    bison
    flex
  ];

  buildInputs = with pkgs; [
    hdx-config.python
    tcl
    readline
    zlib
    libffi
    boost
  ];

  enableParallelBuilding = true;
}
