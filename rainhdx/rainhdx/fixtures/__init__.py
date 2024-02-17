from amaranth import Elaboratable, Module
from amaranth_boards.icebreaker import ICEBreakerPlatform

from .. import Platform, Project


class FixturePlatform(Platform, ICEBreakerPlatform):
    pass


class FixtureTop(Elaboratable):
    def elaborate(self, platform):
        return Module()


class FixtureProject(Project):
    name = "fixture"
    top = FixtureTop
