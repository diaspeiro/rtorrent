#!/bin/sh

FIFO=${RTMOVE_LOG_FIFO:-/tmp/log.fifo}
mkfifo -m 666 "$FIFO" 2>/dev/null || true
( exec 3<>"$FIFO"; exec cat <&3 ) &
