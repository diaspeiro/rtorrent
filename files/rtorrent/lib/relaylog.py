import logging, os

FIFO = os.environ.get("RTMOVE_LOG_FIFO", "/tmp/log.fifo")

_ESCAPE = {c: f"\\x{c:02x}" for c in (*range(0x20), 0x7f)}
def _sanitize(s):
    return s.translate(_ESCAPE)


class FifoHandler(logging.Handler):
    def __init__(self, path=FIFO):
        super().__init__()
        self.path = path

    def emit(self, record):
        try:
            line = (_sanitize(self.format(record)) + "\n").encode("utf-8", "replace")
            fd = os.open(self.path, os.O_WRONLY | os.O_NONBLOCK | os.O_CLOEXEC)
            try:
                os.write(fd, line)
            finally:
                os.close(fd)
        except OSError:
            pass


def get_logger(name):
    log = logging.getLogger(name)
    if not log.handlers:
        log.setLevel(logging.INFO)
        h = FifoHandler()
        h.setFormatter(logging.Formatter(
            "%(asctime)s %(name)s[%(process)d] %(levelname)s %(message)s",
            "%Y-%m-%dT%H:%M:%S%z"))
        log.addHandler(h)
        log.propagate = False
    return log
