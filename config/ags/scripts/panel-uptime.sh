#!/usr/bin/env bash
# Pretty uptime for the dashboard card.
awk '{
  h = int($1 / 3600)
  m = int(($1 % 3600) / 60)
  printf "{\"hours\":%d,\"mins\":%d}\n", h, m
}' /proc/uptime
