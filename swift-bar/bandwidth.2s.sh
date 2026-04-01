#!/bin/bash

# <swiftbar.title>Bandwidth Monitor</swiftbar.title>
# <swiftbar.refreshInterval>1s</swiftbar.refreshInterval>

CACHE_FILE="/tmp/swiftbar_bandwidth_cache"

# Get the active network interface (usually en0 for Wi-Fi)
INTERFACE=$(route get default 2>/dev/null | awk '/interface: / {print $2}')
[ -z "$INTERFACE" ] && INTERFACE="en0"

# Grab the current total bytes in natively via netstat
STATS=$(netstat -I "$INTERFACE" -b | awk '/Link/ {print $7, $10}' | head -n 1)
IN_BYTES=$(echo "$STATS" | awk '{print $1}')
OUT_BYTES=$(echo "$STATS" | awk '{print $2}') # Keeping variable for the cache file
CUR_TIME=$(date +%s)

if [ -f "$CACHE_FILE" ]; then
    read PREV_TIME PREV_IN PREV_OUT < "$CACHE_FILE"
    TIME_DIFF=$((CUR_TIME - PREV_TIME))

    if [ "$TIME_DIFF" -gt 0 ]; then
        IN_DIFF=$((IN_BYTES - PREV_IN))
        # OUT_DIFF=$((OUT_BYTES - PREV_OUT))

        # Bytes per second
        IN_SPEED=$((IN_DIFF / TIME_DIFF))
        # OUT_SPEED=$((OUT_DIFF / TIME_DIFF))

        # Format to human readable (B/s, KB/s, MB/s) using awk
        IN_FMT=$(awk -v b="$IN_SPEED" 'BEGIN { if(b>1048576) printf "%.1f MB/s", b/1048576; else if(b>1024) printf "%.1f KB/s", b/1024; else printf "%d B/s", b }')
        # OUT_FMT=$(awk -v b="$OUT_SPEED" 'BEGIN { if(b>1048576) printf "%.1f MB/s", b/1048576; else if(b>1024) printf "%.1f KB/s", b/1024; else printf "%d B/s", b }')

        # Output for SwiftBar (Only Download Speed, default macOS font)
        # echo "↓ $IN_FMT • ↑ $OUT_FMT"
        echo "↓ $IN_FMT"
    else
        echo "Calculating..."
    fi
else
    echo "Calculating..."
fi

# Save the current state to a temp file for the next tick
echo "$CUR_TIME $IN_BYTES $OUT_BYTES" > "$CACHE_FILE"
