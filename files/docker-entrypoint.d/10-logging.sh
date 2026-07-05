#!/bin/sh

FIFO=${RTMOVE_LOG_FIFO:-/tmp/log.fifo}
mkfifo -m 666 "$FIFO" 2>/dev/null || true
( exec 3<>"$FIFO"; exec cat <&3 ) &

# fifo is created in a subshell, so wait for it
for i in $(seq 100); do [ -p "$FIFO" ] && break; sleep 0.1; done
[ -p "$FIFO" ] || { echo "timeout: $FIFO did not appear" >&2; exit 1; }
