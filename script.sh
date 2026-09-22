#!/usr/bin/env bash

INTERVAL_SECONDS=5
LOG_FILE="monitor.log"

while true; do
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---" >> "$LOG_FILE"
    uptime >> "$LOG_FILE"
    free -h >> "$LOG_FILE"
    df -h >> "$LOG_FILE"
    echo >> "$LOG_FILE"

    sleep "$INTERVAL_SECONDS"
done
