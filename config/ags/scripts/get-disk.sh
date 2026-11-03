#!/usr/bin/env bash
target="${1:-/}"
printf "%.0f\n" "$(df --output=pcent "$target" | tail -n1 | tr -dc '0-9')"

