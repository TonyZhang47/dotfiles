#!/usr/bin/env bash
# Full date plus a month grid, matching the tooltip the waybar clock showed.
date '+%A, %d %B %Y'
echo
cal --color=never 2>/dev/null || cal
