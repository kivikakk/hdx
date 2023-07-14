{
  pkgs,
  stdenv,

  python,
  git,

  hdx-versions,
}:

stdenv.mkDerivation {
  name = "yosys";

  srcs = [
    (pkgs.fetchgit {
      name = "yosys";
      url = "https://github.com/YosysHQ/yosys.git";
      inherit (hdx-versions.yosys) rev sha256;
    })
    (pkgs.fetchgit {
      name = "abc";
      url = "https://github.com/YosysHQ/abc.git";
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

  makeFlags = [
    "PREFIX=$(out)"
    "PRETTY=0"
    # https://github.com/YosysHQ/yosys/issues/2011
    "CONFIG=clang"
    "ABCMKARGS+=CC=cc"
    "CXX=c++"
    "LD=c++"
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
