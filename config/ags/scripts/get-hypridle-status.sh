#!/bin/bash
# "true" means the idle lock is on. The sleep-only helper does not count:
# it only locks when the machine actually suspends.
if pgrep -a -x hypridle | grep -q -F '/hypr/hypridle.conf'; then
    echo "true"
else
    echo "false"
fi
