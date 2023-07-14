{
  amaranth = {
    rev = "ea36c806630904aa5b5c18042207a62ca9045d12";
    sha256s = {
      # XXX Well; isn't this the worst? Until I workaround
      # NixOS/nixpkgs#8567 better.
      x86_64-linux = "OcgXn5sgTssl1Iiu/YLZ2fUgfCZXomsF/MDc85BCCaQ=";
      aarch64-darwin = "afMA0nj+HQD0rxNqgf6dtI1lkUCetirnxQToDxE987g=";
    };

  };

  yosys = {
    rev = "14d50a176d59a5eac95a57a01f9e933297251d5b";
    sha256 = "1SiCI4hs59Ebn3kh7GESkgHuKySPaGPRvxWH7ajSGRM=";
  };
  abc = {
    rev = "bb64142b07794ee685494564471e67365a093710";
    sha256 = "Qkk61Lh84ervtehWskSB9GKh+JPB7mI1IuG32OSZMdg=";
  };

  nextpnr = {
    rev = "54b2045726fc3fe77857c05c81a5ab77e98ba851";
    sha256 = "BhNQKACh8ls2cnQ9tMn8YSrpEiIz5nqhcnuYLnEbJXw=";
  };
  icestorm = {
    rev = "d20a5e9001f46262bf0cef220f1a6943946e421d";
    sha256 = "dEBmxO2+Rf/UVyxDlDdJGFAeI4cu1wTCbneo5I4gFG0=";
  };
  trellis = {
    rev = "e830a28077e1a789d32e75841312120ae624c8d6";
    sha256 = "COC5iPJHkpfB6rZUAz1P6EvpdqfbSLsc59dhAm1nXMA=";
  };

  symbiyosys = {
    rev = "fbbbab235f4ecdce6353cb6c9062d790c450dddc";
    sha256 = "F2kylUuX1cbVnyEvObRr4l8EoqJIzZJjwpFyNyy+iP8=";
  };
  z3 = {
    rev = "z3-4.12.2";
    sha256 = "DTgpKEG/LtCGZDnicYvbxG//JMLv25VHn/NaF307JYA=";
  };
}
