from pathlib import Path

import png
from amaranth import (Array, Cat, ClockDomain, Elaboratable, Instance, Memory,
                      Module, Mux, Signal, unsigned)
from amaranth.build import Attrs, Pins, PinsN, Resource

__all__ = ["Top"]

USE_PLL = False
PRESCALER_COUNT = 1
PPR = 64
BPP = 8

w = 64
h = 64
rows = [[0] * (w * 3)] * h


class Top(Elaboratable):
    def elaborate(self, platform):
        m = Module()

        image_rps = []
        for half in range(2):
            image_mem = Memory(
                width=24,
                depth=64 * 32,
                init=[
                    (rows[row][col * 3])
                    | ((rows[row][col * 3 + 1]) << 8)
                    | ((rows[row][col * 3 + 2]) << 16)
                    for row in range(32 * half, 32 * (half + 1))
                    for col in range(64)
                ],
            )
            m.submodules[f"image{half}_rp"] = irp = image_mem.read_port()
            image_rps.append(irp)

        if USE_PLL:
            cd_sync = ClockDomain("sync")
            m.domains += cd_sync

            platform.add_clock_constraint(cd_sync.clk, 48e6)

            # icepll -i 12 -o 48 -p -m
            m.submodules.pll = Instance(
                "SB_PLL40_PAD",
                p_FEEDBACK_PATH="SIMPLE",
                p_DIVR=0,
                p_DIVF=63,
                p_DIVQ=4,
                p_FILTER_RANGE=1,
                i_PACKAGEPIN=platform.request("clk12", dir="-").io,
                i_RESETB=1,
                o_PLLOUTCORE=cd_sync.clk,
            )

        pled = platform.request("led").o

        platform.add_resources(platform.break_off_pmod)
        btn_0 = platform.request("button", 1)
        btn_1 = platform.request("button", 2)

        platform.add_resources(
            [
                Resource(
                    "rgb_panel_lh",
                    0,
                    Pins("1 7 2 8 3 9 4 10", dir="o", conn=("pmod", 0)),
                    Attrs(IO_STANDARD="SB_LVCMOS"),
                ),
                Resource(
                    "rgb_panel_rh",
                    0,
                    Pins("1 2 3 4 10 7 8 9", dir="o", conn=("pmod", 1)),
                    Attrs(IO_STANDARD="SB_LVCMOS"),
                ),
            ]
        )
        panel_lh = platform.request("rgb_panel_lh")
        panel_rh = platform.request("rgb_panel_rh")

        rgb_r = Signal(2)
        rgb_g = Signal(2)
        rgb_b = Signal(2)
        m.d.comb += panel_lh.o.eq(Cat(rgb_r, rgb_g, rgb_b))

        rgb_row = Signal(5, reset=0b11111)
        rgb_blank = Signal(reset=1)
        rgb_latch = Signal()
        rgb_clock = Signal()
        m.d.comb += panel_rh.o.eq(Cat(rgb_row, rgb_blank, rgb_latch, rgb_clock))

        # Largely following this: https://rhye.org/post/fpgas-2-led-panel-display/
        #
        time_periods = Array(
            Signal(
                range(129),
                reset=i,
            )
            for i in [1, 2, 4, 8, 16, 32, 64, 128][8 - BPP :]
        )
        assert len(time_periods) == BPP

        show_for = Signal(range(129), reset=128)

        pixel_index = Signal(range(PPR))
        pixel_bit_index = Signal(range(BPP), reset=BPP - 1)

        discard = Signal(range(8))
        button_prescaler = Signal(10)
        with m.If((rgb_row == 0) & (pixel_index == 0) & (pixel_bit_index == 0)):
            m.d.sync += button_prescaler.eq(button_prescaler + 1)
            with m.If(button_prescaler == 0):
                with m.If(btn_0.i):
                    m.d.sync += discard.eq(discard + 1)

        m.d.comb += (
            [
                rp.en.eq(1),
                rp.addr.eq((rgb_row + 1)[:5] * 64 + pixel_index),
            ]
            for rp in image_rps
        )

        prescaler_reg = Signal(range(PRESCALER_COUNT))
        with m.If(prescaler_reg != 0):
            m.d.sync += prescaler_reg.eq(prescaler_reg - 1)
        with m.Else():
            m.d.sync += prescaler_reg.eq(PRESCALER_COUNT - 1)
            with m.FSM():
                with m.State("s_data_shift"):
                    with m.If(show_for != 0):
                        m.d.sync += show_for.eq(show_for - 1)
                    with m.Else():
                        m.d.sync += rgb_blank.eq(1)

                    with m.If(rgb_clock == 0):
                        for lhs, offset in [(rgb_r, 0), (rgb_g, 8), (rgb_b, 16)]:
                            m.d.sync += lhs.eq(
                                Cat(
                                    Mux(
                                        (7 - pixel_bit_index) >= discard,
                                        rp.data.bit_select(
                                            pixel_bit_index + offset + discard,
                                            1,
                                        ),
                                        0,
                                    )
                                    for rp in image_rps
                                )
                            )
                        m.d.sync += rgb_clock.eq(1)
                    with m.Else():
                        m.d.sync += [
                            rgb_clock.eq(0),
                            pixel_index.eq(pixel_index + 1),
                        ]
                        with m.If(pixel_index == PPR - 1):
                            m.d.sync += [
                                rgb_latch.eq(1),
                            ]
                            m.next = "s_wait_done"

                with m.State("s_wait_done"):
                    with m.If(show_for != 0):
                        m.d.sync += show_for.eq(show_for - 1)
                    with m.Else():
                        m.d.sync += [
                            rgb_blank.eq(1),
                        ]
                        m.next = "s_increment_row"

                with m.State("s_increment_row"):
                    m.d.sync += [
                        rgb_row.eq(rgb_row + 1),
                        rgb_latch.eq(0),
                        show_for.eq(time_periods[pixel_bit_index]),
                        rgb_blank.eq(Mux((7 - pixel_bit_index) >= discard, 0, 1)),
                        pixel_index.eq(0),
                    ]
                    with m.If(rgb_row == 0):
                        m.d.sync += pixel_bit_index.eq(
                            Mux(pixel_bit_index == 0, BPP - 1, pixel_bit_index - 1)
                        )

                    m.next = "s_data_shift"

        led = Signal()
        m.d.comb += pled.eq(led)

        counter_max = int(platform.freq // 8)
        counter = Signal(range(counter_max + 1))
        with m.If(counter == counter_max):
            m.d.sync += [
                counter.eq(0),
                led.eq(~led),
            ]
        with m.Else():
            m.d.sync += counter.eq(counter + 1)

        return m
