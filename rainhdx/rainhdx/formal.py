import subprocess
from functools import partial

from amaranth import ClockSignal, Signal
from amaranth.back import rtlil

__all__ = ["add_arguments", "FormalHelper"]


def add_arguments(rp, parser):
    parser.set_defaults(func=partial(main, rp))
    parser.add_argument(
        "tasks",
        help="tasks to run; defaults to all",
        nargs="*",
    )


def main(rp, args):
    from . import Platform

    design = rp.formal_top()
    output = rtlil.convert(
        design,
        platform=Platform["test"],
        name=f"{rp.name}_formal",
        ports=design.ports,
    )
    with open(rp.path.build(f"{rp.name}_formal.il"), "w") as f:
        f.write(output)
    with open(rp.path.build(f"{rp.name}_formal.sby"), "w") as f:
        f.write(make_sby(rp))
    subprocess.run(
        [
            "sby",
            "--prefix",
            rp.path.build(f"{rp.name}_formal"),
            "-f",
            rp.path.build(f"{rp.name}_formal.sby"),
            *args.tasks,
        ],
        check=True,
    )


class FormalHelper:
    @property
    def ports(self):
        raise NotImplementedError("define the 'ports' property on your formal class")

    @staticmethod
    def past(m, s, *, cycles=2, stable1=None):
        if isinstance(s, ClockSignal):
            name = "clk_past"
        else:
            name = f"{s.name}_past"

        curr = s
        for i in range(cycles):
            next = Signal.like(s, name=f"{name}_{i}")
            m.d.sync += next.eq(curr)

            if stable1 is not None and i == 0:
                with m.If(stable1):
                    m.d.comb += Assume(curr == next)

            curr = next
        return curr


def make_sby(rp):
    return f"""
[tasks]
bmc
cover
prove

[options]
bmc: mode bmc
cover: mode cover
prove: mode prove
depth 30
multiclock on

[engines]
bmc: smtbmc z3
cover: smtbmc z3
prove: smtbmc z3

[script]
read_verilog <<END
module \$dff (CLK, D, Q);
  parameter WIDTH = 0;
  parameter CLK_POLARITY = 1'b1;
  input CLK;
  input [WIDTH-1:0] D;
  output reg [WIDTH-1:0] Q;
  \$ff #(.WIDTH(WIDTH)) _TECHMAP_REPLACE_ (.D(D),.Q(Q));
endmodule
END
design -stash dff2ff
read_ilang {rp.name}_formal.il
proc
techmap -map %dff2ff {rp.name}_formal/w:clk %co*
prep -top {rp.name}_formal

[files]
build/{rp.name}_formal.il
"""
