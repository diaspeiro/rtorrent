#!/bin/sh

mkfifo -m 666 /tmp/log.fifo 2>/dev/null || true
( exec 3<>/tmp/log.fifo; exec cat <&3 ) &
