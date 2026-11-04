#!/bin/bash
# Root half of the shutdown fix. The user service already closes Hyprland
# before asus-shutdown removes the dGPU. These drop-ins keep a slow shutdown
# from being cut off at 5s, and keep the stop list off the console.
set -euo pipefail

install -d /etc/systemd/logind.conf.d /etc/systemd/system.conf.d /etc/sysctl.d

cat >/etc/systemd/logind.conf.d/inhibit-delay.conf <<'EOF'
[Login]
InhibitDelayMaxSec=20
EOF

cat >/etc/systemd/system.conf.d/quiet-status.conf <<'EOF'
[Manager]
ShowStatus=no
LogLevel=warning
EOF

cat >/etc/sysctl.d/20-quiet-console.conf <<'EOF'
kernel.printk = 3 3 3 3
EOF

sysctl --system >/dev/null
systemctl daemon-reexec
