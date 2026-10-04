#!/bin/bash

# AMD (Tctl) first, then Intel core, then any sensors temp, then a thermal zone.
cpu_temp=$(sensors 2>/dev/null | awk '/^Tctl:/ {print $2; exit}' | tr -d '+°C' | cut -d'.' -f1)

if [ -z "$cpu_temp" ]; then
    cpu_temp=$(sensors 2>/dev/null | awk '/^Core 0/ {print $3; exit}' | tr -d '+°C' | cut -d'.' -f1)
fi

if [ -z "$cpu_temp" ]; then
    cpu_temp=$(sensors 2>/dev/null | awk '/^temp1:/ {print $2; exit}' | tr -d '+°C' | cut -d'.' -f1)
fi

if [ -z "$cpu_temp" ] && [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    cpu_temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
fi

if [ -z "$cpu_temp" ]; then
    echo 0
else
    echo "$cpu_temp"
fi
