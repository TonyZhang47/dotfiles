#!/bin/bash
# Install root units that keep CPU boost off across reboot, sleep, and fan profiles.
set -euo pipefail
SRC=/home/ping/.config/rice/cpu-boost-off.sh
install -m755 "$SRC" /usr/local/sbin/cpu-boost-off

cat >/etc/systemd/system/cpu-boost-off.service <<'EOF'
[Unit]
Description=Force CPU frequency boost off
After=sysinit.target asusd.service
StartLimitIntervalSec=0
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/cpu-boost-off
EOF

cat >/etc/systemd/system/cpu-boost-off.path <<'EOF'
[Unit]
Description=Keep CPU frequency boost off when a profile turns it back on
After=sysinit.target
[Path]
PathChanged=/sys/devices/system/cpu/cpufreq/boost
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/cpu-boost-off-boot.service <<'EOF'
[Unit]
Description=Force CPU frequency boost off at boot
After=sysinit.target asusd.service multi-user.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/cpu-boost-off
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/cpu-boost-off-resume.service <<'EOF'
[Unit]
Description=Force CPU frequency boost off after sleep
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/cpu-boost-off
[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF

cat >/etc/tmpfiles.d/disable-cpu-boost.conf <<'EOF'
w /sys/devices/system/cpu/cpufreq/boost - - - - 0
w /sys/devices/system/cpu/cpu*/cpufreq/boost - - - - 0
EOF

systemctl daemon-reload
systemctl enable --now cpu-boost-off.path
systemctl enable --now cpu-boost-off-boot.service
systemctl enable cpu-boost-off-resume.service
/usr/local/sbin/cpu-boost-off
