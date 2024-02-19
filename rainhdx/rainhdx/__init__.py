import json
import logging
import sys
from argparse import ArgumentParser
from functools import partialmethod
from pathlib import Path

from amaranth import Elaboratable

from . import build, formal, logger, test
from .platform import Platform

__all__ = ["Project", "Platform", "FormalHelper", "cli"]

FormalHelper = formal.FormalHelper


class Prop:
    def __init__(
        self, name, *, description, required, isinstance=None, issubclass=None
    ):
        self.name = name
        self.description = description
        self.required = required
        self.isinstance = isinstance
        self.issubclass = issubclass

    def validate(self, project):
        if self.required:
            assert hasattr(project, self.name), (
                f"{project.__module__}.{project.__class__.__qualname__} is missing "
                f"property {self.name!r} ({self.description})"
            )
        elif not hasattr(project, self.name):
            return

        attr = getattr(project, self.name)
        if self.isinstance:
            assert isinstance(attr, self.isinstance), (
                f"{project.__module__}.{project.__class__.__qualname__} property "
                f"{self.name!r} ({self.description}) should an instance of "
                f"{self.isinstance!r}, but is {attr!r}"
            )
        if self.issubclass:
            assert issubclass(attr, self.issubclass), (
                f"{project.__module__}.{project.__class__.__qualname__} property "
                f"{self.name!r} ({self.description}) should be a subclass of "
                f"{self.issubclass!r}, but is {attr!r}"
            )


class Project:
    PROPS = [
        Prop(
            "name",
            description="a keyword-like identifier for the project",
            required=True,
            isinstance=str,
        ),
        Prop(
            "top",
            description="a reference to the default top-level elaboratable to be built",
            required=True,
            issubclass=Elaboratable,
        ),
        Prop(
            "formal_top",
            description="a reference to the top-level formal elaboratable",
            required=False,
            issubclass=Elaboratable,
        ),
    ]

    def __init_subclass__(self):
        # We expect to be called from project-root/module/__init.py__ or similar;
        # self.origin is project-root.
        self.origin = Path(sys._getframe(1).f_code.co_filename).parent.parent.absolute()
        extras = self.__dict__.keys() - {"__module__", "__doc__", "origin"}
        for prop in self.PROPS:
            prop.validate(self)
            extras -= {prop.name}
        assert extras == set(), f"unknown project properties: {extras}"

    @property
    def path(self):
        return ProjectPath(self)


class ProjectPath:
    def __init__(self, rp):
        self.rp = rp

    def __call__(self, *components):
        return self.rp.origin.joinpath(*components)

    def build(self, *components):
        return self("build", *components)


def cli(rp):
    parser = ArgumentParser(prog=rp.name)
    subparsers = parser.add_subparsers(required=True)

    test.add_arguments(rp, subparsers.add_parser("test", help="run the unit tests"))
    # cxxsim
    if hasattr(rp, "formal_top"):
        formal.add_arguments(
            rp, subparsers.add_parser("formal", help="formally verify the design")
        )
    build.add_arguments(
        rp,
        subparsers.add_parser(
            "build", help="build the design, and optionally program it"
        ),
    )

    if len(sys.argv) >= 2 and sys.argv[1] == "internal":
        internal = subparsers.add_parser("internal")
        add_internal_commands(rp, internal.add_subparsers(required=True))

    args = parser.parse_args()
    args.func(args)


def add_internal_commands(rp, parser):
    def boards(args):
        json.dump(sorted(Platform.build_targets), sys.stdout)

    parser.add_parser(
        "boards", help="dump the boards supported by this project as a JSON list"
    ).set_defaults(func=boards)

    def formal(args):
        sys.exit(0)

    parser.add_parser(
        "formal",
        help="return zero if this project support formal testing, non-zero otherwise",
    ).set_defaults(func=formal)
