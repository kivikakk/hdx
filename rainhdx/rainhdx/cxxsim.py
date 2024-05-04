import inspect
import subprocess
from enum import Enum
from functools import partial
from pathlib import Path

from amaranth._toolchain.yosys import find_yosys
from amaranth.back import rtlil

from .logger import logger
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
        "-d",
        "--debug",
        action="store_true",
        help="generate source-level debug information",
    )
    parser.add_argument(
        "-v",
        "--vcd",
        action="store_true",
        help="output a VCD file",
    )
    parser.add_argument(
        "other_compile",
        nargs="*",
        help="other compile-time arguments",
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
        cxxrtl_cc_path: rp.path.build(f"{rp.name}.o"),
    }
    for path in rp.path("cxxsim").glob("*.cc"):
        cc_o_paths[path] = rp.path.build(f"{path.stem}.o")

    procs = []
    for cc_path, o_path in cc_o_paths.items():
        cmd = [
            "c++",
            *(["-O3"] if args.optimize.opt_rtl else ["-O0"]),
            *(["-g"] if args.debug else []),
            *args.other_compile,
            "-Wall",
            "-I" + str(rp.path("build")),
            "-I" + str(yosys.data_dir() / "include" / "backends" / "cxxrtl" / "runtime"),
            "-c",
            cc_path,
            "-o",
            o_path,
        ]
        logger.debug(" ".join(str(e) for e in cmd))
        procs.append((cc_path, subprocess.Popen(cmd)))

    failed = []
    for cc_path, p in procs:
        if p.wait() != 0:
            failed.append(cc_path)

    if failed:
        logger.error("Failed to build paths:")
        for p in failed:
            logger.error(f"- {p}")
        raise RuntimeError("failed compile step")

    exe_o_path = rp.path.build("cxxsim")
    cmd = [
        "c++",
        *(["-O3"] if args.optimize.opt_rtl else []),
        *args.other_compile,
        *cc_o_paths.values(),
        "-o",
        exe_o_path,
    ]
    logger.debug(" ".join(str(e) for e in cmd))
    subprocess.run(cmd, check=True)

    if not args.compile:
        cmd = [exe_o_path]
        if args.vcd:
            cmd += ["--vcd"]
        logger.debug(" ".join(str(e) for e in cmd))
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
