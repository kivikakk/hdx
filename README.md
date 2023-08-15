# hdx 

hdx packages an open-source FPGA toolchain on Nix.  You get the following:

* [Python 3].11
* [Amaranth]
* [Yosys]
* [nextpnr]
* [Project IceStorm]
* [Project Trellis]
* [SymbiYosys]
* [Yices 2]
* [Z3]

With the exclusion of Python, the package definitions are written de novo.  This
has a few nice properties:

* It's pretty easy to see what's going on.
* Want to add another target to nextpnr ~~anyway, for a laugh~~?  ~~We had
  a tool for that~~ It's easy to do, and you don't have to bring up a Nixpkgs
  overlay, refactor the chipdb derivation out when you get tired of the build
  times and still don't have it working yet, and then override nextpnr or
  something.
  * Bonus: HEAD versions of ~everything actually build (*and check*), even on
    nix-darwin.  Quite a few things in Nixpkgs won't.  (See [Hacks](#hacks).)
* You can mess with the Python version used by the whole toolchain, without
  having to (a) override all of them and (b) subsequently understand all of them
  in Nixpkgs when they refuse to build or quietly give you dynamic linking
  errors at runtime.
* The reason I wanted this: you can use Amaranth and/or Yosys in "development
  mode", and have your on-disk checkouts of them used by the whole toolchain.

[Python 3]: https://www.python.org/
[Amaranth]: https://github.com/amaranth-lang/amaranth
[Yosys]: https://github.com/YosysHQ/yosys
[nextpnr]: https://github.com/YosysHQ/nextpnr
[Project IceStorm]: https://github.com/YosysHQ/icestorm
[Project Trellis]: https://github.com/YosysHQ/prjtrellis
[SymbiYosys]: https://github.com/YosysHQ/sby
[Yices 2]: https://github.com/SRI-CSL/yices2
[Z3]: https://github.com/Z3Prover/z3


## Modes of operation

* `nix develop github:charlottia/hdx` / `nix-shell`

  This is the default mode of operation.  The above packages are built and added
  to `PATH`.

  Amaranth is configured to use the Yosys built by hdx, and not its built-in
  one.

* `nix develop github:charlottia/hdx#amaranth` / `nix-shell $HDX/amaranth-dev-shell.nix`

  Like above, except Amaranth is not built and installed.  Instead, an Amaranth
  checkout in `./` or `./amaranth/` is expected, and installed in editable
  mode.

* `nix develop github:charlottia/hdx#yosys-amaranth` / `nix-shell $HDX/yosys-amaranth-dev-shell.nix`

  Like above, except the Amaranth checkout must be at `./amaranth/` and
  a Yosys checkout is expected at `./yosys/`.  Yosys is configured to
  be compiled and installed to `./hdx-out/`, and `PATH` has the output
  directory's `bin` subdirectory prepended.  You'll need to actually `make
  install` Yosys at least once for this mode to function, including any use of
  Amaranth that depends on Yosys.

* Your project's `flake.nix`

  ```nix
  {
    inputs.hdx.url = github:charlottia/hdx;

    outputs = {
      self,
      nixpkgs,
      flake-utils,
      hdx,
    }:
      flake-utils.lib.eachDefaultSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            hdx.packages.${system}.default
          ];
        };
      });
  }
  ```

* Your project's `shell.nix`

  ```nix
  {pkgs ? import <nixpkgs> {}}: let
    hdx = (import (pkgs.fetchFromGitHub {
      owner = "charlottia";
      repo = "hdx";
      rev = "56e94f4b95d63bf4faeae839f5da06dffe85417f";
      sha256 = "5TWmue+hPxtuwcXEavB2U+n89p3YcRqsQNjY2NCMPLE=";
    })).default;
  in
    pkgs.mkShell {
      name = "weapon";
      nativeBuildInputs = [
        hdx
      ];
    }
  ```


## Hacks

* Python on Nix's `sitecustomize.py` drops `NIX_PYTHONPATH` from the
  environment when processing it, causing children opened with `subprocess` to
  not be aware of packages that might've been added by that mechanism.  This
  breaks some of Amaranth's tests.

* nix-darwin specific: IceStorm's `icebox/Makefile` determines its `sed` use
  based on `uname`.  [You may not do that].

  [You may not do that]: https://aperture.ink/@charlotte/110737824873379605

* SymbiYosys's `sbysrc/sby_core.py` invokes `/usr/bin/env`.  It may not
  exist.

* Z3's `z3.pc.cmake.in` prepends `${exec_prefix}/` et al. to
  `@CMAKE_INSTALL_LIBDIR@` et al.  This produces frakenpaths on Nix.


## Background

hdx reproduces the setup described in [Installing an HDL toolchain from source]
in Nix.

[Installing an HDL toolchain from source]: https://lottia.net/notes/0001-hdl-toolchain-source.html
