#!/bin/bash
# "false" means the idle lock is on. The sleep-only helper does not count:
# it only locks when the machine actually suspends.
if pgrep -a -x hypridle | grep -q -F '/hypr/hypridle.conf'; then
    echo "false"
else
    echo "true"
fi
