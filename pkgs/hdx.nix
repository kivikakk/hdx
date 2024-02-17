{
  stdenv,
  makeWrapper,
  python,
  amaranth,
  amaranth-boards,
  amaranth-stdio,
  yosys,
  abc,
  nextpnr,
  symbiyosys,
  z3_4_12,
  yices,
  icestorm,
  trellis,
}:
stdenv.mkDerivation {
  name = "hdx";

  dontUnpack = true;

  propagatedBuildInputs = [
    python
    amaranth
    amaranth-boards
    amaranth-stdio
    yosys
    abc
    nextpnr
    symbiyosys
    z3_4_12
    yices
    icestorm
    trellis
  ];

  buildInputs = [makeWrapper];

  inherit (amaranth) AMARANTH_USE_YOSYS;

  installPhase = ''
    for b in ${python}/bin/*; do
      makeWrapper "$b" "$out/bin/$(basename "$b")" --inherit-argv0 --set AMARANTH_USE_YOSYS ${amaranth.AMARANTH_USE_YOSYS}
    done
  '';
}
