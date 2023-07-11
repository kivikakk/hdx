{
  pkgs,
  stdenv,
  fetchgit,
  fetchzip,

  hdxPython,

  yosys_rev,
  yosys_git_sha256,
  abc_rev,
  abc_tgz_sha256,
}:

stdenv.mkDerivation {
  name = "yosys";

  srcs = [
    (fetchgit {
      name = "yosys";
      url = "https://github.com/YosysHQ/yosys.git";
      rev = yosys_rev;
      sha256 = yosys_git_sha256;
    })
    (fetchzip {
      name = "abc";
      url = "https://github.com/YosysHQ/abc/archive/${abc_rev}.tar.gz";
      sha256 = abc_tgz_sha256;
    })
  ];

  sourceRoot = "yosys";

  postUnpack = ''
    cp -r abc yosys
    chmod -R u+w yosys/abc
    echo -n ${yosys_rev} >yosys/.gitcommit

    # Confirm abc we asked for matches yosys default.
    abcrev="$((make -qpf yosys/Makefile 2>/dev/null || true) | awk -F' = ' '$1=="ABCREV" {print $2}')"
    echo "$abcrev" | grep -qiE '^[a-f0-9]+$'
    echo "${abc_rev}" | grep -q ^"$abcrev"
  '';

  configurePhase = ''
    cat >Makefile.conf <<EOF
    PREFIX = $prefix
    CONFIG = gcc
    PRETTY = 0
    EOF
  '';

  nativeBuildInputs = with pkgs; [
    which

    pkg-config
    git
    tcl
    bison
    flex
    hdxPython

    readline
    zlib
    libffi
    (boost.override { python = hdxPython; enablePython = true; })
  ];

  enableParallelBuilding = true;
}
