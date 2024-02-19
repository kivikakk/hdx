import sys
from functools import partial
from pathlib import Path
from unittest import TestLoader, TextTestRunner

__all__ = ["add_arguments"]


def add_arguments(rp, parser):
    parser.set_defaults(func=partial(main, rp))
    parser.add_argument(
        "subdir", nargs="?", help="run tests from a specific subdirectory"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="be verbose (don't buffer output)"
    )


def main(rp, args):
    top_level = Path(rp.origin)
    base = args.subdir or top_level
    suite = TestLoader().discover(base, top_level_dir=top_level)
    result = TextTestRunner(buffer=not args.verbose, verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
