import importlib
import inspect
import logging
import re
from datetime import datetime
from functools import partial

from .logger import logger, logtime
from .platform import Platform

__all__ = ["add_arguments"]


def add_arguments(rp, parser):
    parser.set_defaults(func=partial(main, rp))
    default_top = f"{rp.top.__module__}.{rp.top.__qualname__}"
    parser.add_argument(
        "-t",
        "--top",
        help=f"which top-level module to build (default: {default_top})",
    )
    match sorted(Platform.build_targets):
        case []:
            raise RuntimeError("no buildable targets defined")
        case [first, *rest]:
            parser.add_argument(
                "-b",
                "--board",
                choices=[first, *rest],
                help="which board to build for",
                required=bool(rest),
                **({"default": first} if not rest else {}),
            )
    parser.add_argument(
        "-p",
        "--program",
        action="store_true",
        help="program the design onto the board after building",
    )
    parser.add_argument(
        "-v",
        "--verilog",
        action="store_true",
        help="output debug Verilog",
    )


def main(rp, args):
    logger.info("building %s for %s", rp.name, args.board)
    platform = Platform[args.board]

    elaboratable = construct_top(rp, args, platform)

    with logtime(logging.DEBUG, "RTLIL generation"):
        plan = platform.prepare(
            elaboratable, rp.name, debug_verilog=args.verilog, yosys_opts="-g"
        )
    fn = f"{rp.name}.il"
    size = len(plan.files[fn])
    logger.debug(f"{fn!r}: {size:,} bytes")

    with logtime(logging.DEBUG, "synthesis"):
        products = plan.execute_local("build")

    if args.program:
        with logtime(logging.DEBUG, "programming"):
            platform.toolchain_program(products, rp.name)

    heading = re.compile(r"^\d+\.\d+\. Printing statistics\.$", flags=re.MULTILINE)
    next_heading = re.compile(r"^\d+\.\d+\. ", flags=re.MULTILINE)
    log_file_between(logging.INFO, f"build/{rp.name}.rpt", heading, next_heading)

    logger.info("Device utilisation:")
    heading = re.compile(r"^Info: Device utilisation:$", flags=re.MULTILINE)
    next_heading = re.compile(r"^Info: Placed ", flags=re.MULTILINE)
    log_file_between(
        logging.INFO, f"build/{rp.name}.tim", heading, next_heading, prefix="Info: "
    )


def construct_top(rp, args, platform, **kwargs):
    if args.top is not None:
        mod, klass_name = args.top.rsplit(".", 1)
        klass = getattr(importlib.import_module(mod), klass_name)
    else:
        klass = rp.top

    sig = inspect.signature(klass)
    if "platform" in sig.parameters:
        kwargs["platform"] = platform
    return klass(**kwargs)


def log_file_between(level, path, start, end, *, prefix=None):
    with open(path, "r") as f:
        for line in f:
            if start.match(line):
                break
        else:
            return

        for line in f:
            if end.match(line):
                return
            line = line.rstrip()
            if prefix is not None:
                line = line.removeprefix(prefix)
            logger.log(level, line)
