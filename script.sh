#!/usr/bin/env bash

INTERVAL_SECONDS=5
LOG_FILE="monitor.log"

check_dependencies() {
    local command_name

    for command_name in uptime free df date sleep; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            echo "Error: required command '$command_name' not found." >&2
            exit 1
        fi
    done
}

stop_monitoring() {
    echo
    echo "Monitoring stopped."
    exit 0
}

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

trap stop_monitoring INT TERM

check_dependencies

while true; do
    write_snapshot
    sleep "$INTERVAL_SECONDS"
done
