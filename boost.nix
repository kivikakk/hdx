{
  pkgs,
  hdx-config,
}:
pkgs.boost.override {
  inherit (hdx-config) stdenv python;
  enablePython = true;
  extraB2Args = [
    # To build on LLVM 16.
    "define=BOOST_NO_CXX98_FUNCTION_BASE"
    "cxxflags=\"-Wno-enum-constexpr-conversion -target aarch64-apple-darwin\""
  ];
}
