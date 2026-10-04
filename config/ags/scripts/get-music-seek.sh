#!/usr/bin/env bash

POSITION=$(playerctl position 2>/dev/null) || { echo 0; exit 0; }
LENGTH_MICROSECONDS=$(playerctl metadata mpris:length 2>/dev/null) || { echo 0; exit 0; }

if [ -z "$POSITION" ] || [ -z "$LENGTH_MICROSECONDS" ] || [ "$LENGTH_MICROSECONDS" = "0" ]; then
    echo 0
    exit 0
fi

python3 -c "
import sys
position = float(sys.argv[1])
length_seconds = float(sys.argv[2]) / 1000000
if length_seconds <= 0:
    print('0')
else:
    print(f'{(position / length_seconds) * 100:.2f}')
" "$POSITION" "$LENGTH_MICROSECONDS"
