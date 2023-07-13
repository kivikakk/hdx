{
  pkgs,
  stdenv,

  python,
  git,

  yosys_rev,
  yosys_git_sha256,
  abc_rev,
  abc_tgz_sha256,
}:

stdenv.mkDerivation {
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

  makeFlags = [
    "PREFIX=$(out)"
    "CONFIG=gcc"
    "PRETTY=0"
  ];

  nativeBuildInputs = with pkgs; [
    pkg-config
    git
    bison
    flex
  ];

  buildInputs = with pkgs; [
    python
    tcl
    readline
    zlib
    libffi
    (boost.override { inherit python; enablePython = true; })
  ];

  enableParallelBuilding = true;
}
