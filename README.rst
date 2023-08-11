=====
 hdx 
=====

Hello, baby's first little Nix repository thingy.  At present, I'm reproducing
the setup described in `Installing an HDL toolchain from source`_, except
Nix-y.

Modes of operation
==================

+ ``nix develop github:charlottia/hdx`` / ``nix-shell``

  This is the default mode of operation.  The following packages are built from
  definitions in ``pkg/`` and added to ``PATH``:

  * Amaranth_
  * Yosys_
  * nextpnr_
  * `Project IceStorm`_
  * `Project Trellis`_
  * SymbiYosys_
  * `Yices 2`_
  * Z3_

  Amaranth is configured to use the Yosys built by hdx, and not its built-in
  one.

+ ``nix develop .#amaranth`` / ``nix-shell amaranth-dev-shell.nix``

  Like above, except Amaranth is not built and installed.  Instead, the
  submodule checkout at ``dev/amaranth/`` is installed in editable mode.
  This must be invoked with a hdx checkout at cwd.

+ ``nix develop .#yosys-amaranth`` / ``nix-shell yosys-amaranth-dev-shell.nix``

  Like above, except Yosys is also not built and installed.  Instead, the
  submodule checkout at ``dev/yosys/`` is configured to be compiled and
  installed to ``dev/out/``, and ``PATH`` has ``dev/out/bin/`` prepended.
  You'll need to actually ``make install`` Yosys at least once for this mode to
  function, including any use of Amaranth that depends on Yosys.

+ Your project's ``flake.nix``

  .. code:: nix

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

+ Your project's ``shell.nix``

  .. code:: nix

      {pkgs ? import <nixpkgs> {}}: let
        hdx = import (pkgs.fetchFromGitHub {
          owner = "charlottia";
          repo = "hdx";
          rev = "116f2cef9cdc75a33c49c578d3b93b19e68597a7";
          sha256 = "THrX3H1368OP+SXRb+S+cczvCbXubF/5s50VhrtDQbk=";
        }) {};
      in
        pkgs.mkShell {
          name = "weapon";
          nativeBuildInputs = [
            hdx
          ];
        }


.. _Installing an HDL toolchain from source: https://notes.hrzn.ee/posts/0001-hdl-toolchain-source/

.. _Amaranth: https://github.com/amaranth-lang/amaranth
.. _Yosys: https://github.com/YosysHQ/yosys
.. _nextpnr: https://github.com/YosysHQ/nextpnr
.. _Project IceStorm: https://github.com/YosysHQ/icestorm
.. _Project Trellis: https://github.com/YosysHQ/prjtrellis
.. _SymbiYosys: https://github.com/YosysHQ/sby
.. _Yices 2: https://github.com/SRI-CSL/yices2
.. _Z3: https://github.com/Z3Prover/z3


Configurability
===============

Any ``nix-shell`` invocation may take the following arguments:

``nextpnr_archs``
  A list of nextpnr_ architectures to build support for.  Valid items are
  ``"generic"``, ``"ice40"`` and ``"ecp5"``.  At least one must be specified.

More configurability is available, but not yet exposed -- I'm not really sure
what's idiomatic yet.  See `<nix/hdx-config.nix>`_:

+ Any of the packages included can be disabled.

+ If Yosys isn't built, Amaranth's built-in Yosys will be used instead.

There is no equivalent usage for flakes.


Hacks
=====

+ Python on Nix's ``sitecustomize.py`` drops ``NIX_PYTHONPATH`` from the
  environment when processing it, causing children opened with ``subprocess`` to
  not be aware of packages that might've been added by that mechanism.

+ nix-darwin specific: IceStorm's ``icebox/Makefile`` needs to not determine its
  ``sed``` use based   on ``uname``.  `You may not do that`_.

  .. _You may not do that: https://aperture.ink/@charlotte/110737824873379605

+ SymbiYosys's ``sbysrc/sby_core.py`` needs to not invoke ``/usr/bin/env``.  It
  may not exist.

+ Z3's ``z3.pc.cmake.in`` needs to not prepend ``${exec_prefix}/`` et al. to
  ``@CMAKE_INSTALL_LIBDIR@`` et al.
