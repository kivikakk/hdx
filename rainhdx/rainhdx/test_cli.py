import sys
import unittest
from argparse import ArgumentParser
from contextlib import redirect_stdout
from io import StringIO

from amaranth import Elaboratable, Module
from amaranth_boards.icebreaker import ICEBreakerPlatform

from . import Platform, Project, build, logger, test
from .fixtures import FixtureProject

calling_test = False


class TestCLI(unittest.TestCase):
    def setUp(self):
        logger.disable()
        self.addCleanup(logger.enable)

    def test_build_works(self):
        parser = ArgumentParser()
        build.add_arguments(FixtureProject(), parser)
        args, _argv = parser.parse_known_args()
        args.func(args)

    def test_test_works(self):
        global calling_test
        parser = ArgumentParser()
        test.add_arguments(FixtureProject(), parser)
        args, _argv = parser.parse_known_args([])
        stdout = StringIO()
        try:
            with redirect_stdout(stdout):
                with self.assertRaisesRegex(SystemExit, "^0$"):
                    calling_test = True
                    try:
                        args.func(args)
                    finally:
                        calling_test = False
                    self.assertIn("waaauf!", stdout.getvalue())
        except:
            # To aid debugging.
            print(stdout.getvalue(), file=sys.stdout)
            raise
