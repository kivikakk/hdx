from amaranth import Elaboratable, Module, ClockSignal, ResetSignal, Signal
from amaranth.asserts import Assert, Assume, Cover
from rainhdx import FormalHelper


class Top(FormalHelper, Elaboratable):
    def __init__(self):
        super().__init__()

        self.sync_clk = ClockSignal("sync")
        self.sync_rst = ResetSignal("sync")

    @property
    def ports(self):
        return [
            self.sync_clk,
            self.sync_rst,
        ]

    def elaborate(self, platform):
        m = Module()

        sync_clk = ClockSignal("sync")
        sync_rst = ResetSignal("sync")

        sync_clk_past = self.past(m, sync_clk, cycles=1)
        m.d.comb += Assume(sync_clk == ~sync_clk_past)
        m.d.comb += Assume(~sync_rst)

        m.d.comb += Assert(~sync_clk)

        return m
