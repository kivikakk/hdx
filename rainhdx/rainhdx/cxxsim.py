import inspect
import subprocess
from enum import Enum
from functools import partial
from pathlib import Path

from amaranth._toolchain.yosys import find_yosys
from amaranth.back import rtlil

from .platform import Platform

__all__ = ["add_arguments"]


class _Optimize(Enum):
    none = "none"
    rtl = "rtl"

    def __str__(self):
        return self.value

    @property
    def opt_rtl(self) -> bool:
        return self in (self.rtl,)


def add_arguments(rp, parser):
    parser.set_defaults(func=partial(main, rp))
    parser.add_argument(
        "-c",
        "--compile",
        action="store_true",
        help="compile only; don't run",
    )
    parser.add_argument(
        "-O",
        "--optimize",
        type=_Optimize,
        choices=_Optimize,
        help="build with optimizations (default: rtl)",
        default=_Optimize.rtl,
    )
    parser.add_argument(
        "-v",
        "--vcd",
        action="store_true",
        help="output a VCD file",
    )


def main(rp, args):
    yosys = find_yosys(lambda ver: ver >= (0, 10))

    platform = Platform["cxxsim"]
    sig = inspect.signature(rp.cxxsim_top)
    kwargs = {}
    if "platform" in sig.parameters:
        kwargs["platform"] = platform
    design = rp.cxxsim_top(**kwargs)

    cxxrtl_cc_path = rp.path.build(f"{rp.name}.cc")
    _cxxrtl_convert_with_header(
        yosys,
        cxxrtl_cc_path,
        design,
        platform,
        black_boxes={},
        ports=design.ports(platform),
    )

    cc_o_paths = {
        rp.path("cxxsim/main.cc"): rp.path.build("main.o"),
    }

    for cc_path, o_path in cc_o_paths.items():
        subprocess.run(
            [
                "c++",
                *(["-O3"] if args.optimize.opt_rtl else []),
                "-I" + str(rp.path(".")),
                "-I" + str(yosys.data_dir() / "include" / "backends" / "cxxrtl" / "runtime"),
                "-c",
                cc_path,
                "-o",
                o_path,
            ],
            check=True,
        )

    exe_o_path = rp.path.build("cxxsim")
    subprocess.run(
        [
            "c++",
            *(["-O3"] if args.optimize.opt_rtl else []),
            *cc_o_paths.values(),
            "-o",
            exe_o_path,
        ],
        check=True,
    )

    if not args.compile:
        cmd = [exe_o_path]
        if args.vcd:
            cmd += ["--vcd"]
        subprocess.run(cmd, cwd=rp.path("cxxsim"), check=True)


def _cxxrtl_convert_with_header(yosys, cc_out, design, platform, *, black_boxes, ports):
    if cc_out.is_absolute():
        try:
            cc_out = cc_out.relative_to(Path.cwd())
        except ValueError:
            raise AssertionError(
                "cc_out must be relative to cwd for builtin-yosys to write to it"
            )
    rtlil_text = rtlil.convert(design, platform=platform, ports=ports)
    script = []
    for box_source in black_boxes.values():
        script.append(f"read_rtlil <<rtlil\n{box_source}\nrtlil")
    script.append(f"read_rtlil <<rtlil\n{rtlil_text}\nrtlil")
    script.append(f"write_cxxrtl -header {cc_out}")
    yosys.run(["-q", "-"], "\n".join(script))
