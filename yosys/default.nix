{
  pkgs ? import <nixpkgs> {},

  python ? pkgs.python311,

  yosys_rev ? "14d50a176d59a5eac95a57a01f9e933297251d5b",
  yosys_git_sha256 ? "1SiCI4hs59Ebn3kh7GESkgHuKySPaGPRvxWH7ajSGRM=",
  abc_rev ? "bb64142b07794ee685494564471e67365a093710",
  abc_tgz_sha256 ? "Qkk61Lh84ervtehWskSB9GKh+JPB7mI1IuG32OSZMdg=",
}:

pkgs.gcc13Stdenv.mkDerivation {
  name = "yosys";

  srcs = [
    (pkgs.fetchgit {
      name = "yosys";
      url = "https://github.com/YosysHQ/yosys.git";
      rev = yosys_rev;
      sha256 = yosys_git_sha256;
    })
    (pkgs.fetchzip {
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
    python

    readline
    zlib
    libffi
    (boost.override { python = python; enablePython = true; })
  ];

  enableParallelBuilding = true;
}
