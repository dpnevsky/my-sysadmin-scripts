#!/usr/bin/env bash

INTERVAL_SECONDS=5
LOG_FILE="monitor.log"

write_snapshot() {
    {
        echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="

        echo "UPTIME:"
        uptime
        echo

        echo "MEMORY:"
        free -h
        echo

        echo "DISK:"
        df -h
        echo
    } >> "$LOG_FILE"
}

while true; do
    write_snapshot
    sleep "$INTERVAL_SECONDS"
done
