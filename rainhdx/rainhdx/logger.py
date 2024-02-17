import logging
from contextlib import contextmanager
from datetime import datetime

__all__ = ["logger", "logtime", "enable", "disable"]

logging.basicConfig(
    format="[%(asctime)s] %(name)s: %(levelname)s: %(message)s",
    level=logging.DEBUG,
)

logger = logging.getLogger("rainhdx")


@contextmanager
def logtime(level, activity, /, fail_level=None):
    global logger
    start = datetime.now()
    logger.log(level, "starting %s", activity)
    try:
        yield
    except:
        finish = datetime.now()
        logger.log(fail_level or level, "%s failed in %s", activity, finish - start)
        raise
    else:
        finish = datetime.now()
        logger.log(level, "%s finished in %s", activity, finish - start)


wufwuf = logging.Filter("wufwuf")


def disable():
    logger.addFilter(wufwuf)


def enable():
    logger.removeFilter(wufwuf)
