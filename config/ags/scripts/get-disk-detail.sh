#!/bin/bash
target="${1:-/}"
df -h --output=avail "$target" | tail -n1 | awk '{print $1 " free"}'

