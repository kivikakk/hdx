import rainhdx
from amaranth_boards.icebreaker import ICEBreakerPlatform

from . import formal, rtl

__all__ = ["Proj", "icebreaker"]


class Proj(rainhdx.Project):
    name = "proj"
    top = rtl.Top
    formal_top = formal.Top


class icebreaker(ICEBreakerPlatform, rainhdx.Platform):
    pass
