#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemctl --global enable bazaar.service
systemctl enable dconf-update.service
systemctl enable flatpak-nuke-fedora.service
systemctl enable flatpak-preinstall.service
systemctl enable podman.socket
systemctl enable ublue-fix-hostname.service

# Updater
systemctl enable uupd.timer

# Disable the old update timer
systemctl disable rpm-ostreed-automatic.timer
systemctl disable flatpak-system-update.timer
