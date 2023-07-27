=====
 hdx 
=====

Hello, baby's first little Nix repository thingy.  At present, I'm reproducing
the setup described in `Installing an HDL toolchain from source`_, except
Nix-y.

Modes of operation
==================

+ ``nix develop`` / ``nix-shell``

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

+ ``nix develop .#yosys-amaranth`` / ``nix-shell yosys-amaranth-dev-shell.nix``

  Like above, except Yosys is also not built and installed.  Instead, the
  submodule checkout at ``dev/yosys/`` is configured to be compiled and
  installed to ``dev/out/``, and ``PATH`` has ``dev/out/bin/`` prepended.
  You'll need to actually ``make install`` Yosys at least once for this mode to
  function, including any use of Amaranth that depends on Yosys.

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
          nativeBuildInputs = with pkgs; [
            hdx
            pineapple-pictures
            hyfetch
            varscan
            ugarit-manifest-maker
            # ... etc.
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
