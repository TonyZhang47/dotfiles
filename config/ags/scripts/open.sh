#!/usr/bin/env bash
# Launch something from an AGS button without blocking the panel.
[ "$#" -gt 0 ] || exit 0
setsid -f "$@" >/dev/null 2>&1
