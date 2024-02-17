import unittest

from rainhdx import test_cli


class TestShouldBeDiscovered(unittest.TestCase):
    def test_should_run(self):
        if test_cli.calling_test:
            print("waaauf!")
