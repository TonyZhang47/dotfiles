#!/bin/bash
# Force AMD CPU frequency boost off. Fan/ASUS profiles must not turn it back on.
set -eu
BOOST=/sys/devices/system/cpu/cpufreq/boost

write0() {
    [ -w "$1" ] || return 0
    cur=$(cat "$1" 2>/dev/null || echo)
    [ "$cur" = 0 ] && return 0
    printf '0\n' >"$1" || true
}

[ -e "$BOOST" ] && write0 "$BOOST"
for f in /sys/devices/system/cpu/cpu*/cpufreq/boost /sys/devices/system/cpu/cpufreq/policy*/boost; do
    [ -e "$f" ] && write0 "$f"
done
exit 0
