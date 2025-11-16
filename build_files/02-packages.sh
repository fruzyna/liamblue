#!/usr/bin/bash

set -ouex pipefail

# All DNF-related operations should be done here whenever possible

# NOTE:
# Packages are split into FEDORA_PACKAGES and COPR_PACKAGES to prevent
# malicious COPRs from injecting fake versions of Fedora packages.
# Fedora packages are installed first in bulk (safe).
# COPR packages are installed individually with isolated enablement.

# Base packages from Fedora repos - common to all versions
FEDORA_PACKAGES=(
    # TODO: dependencies for running Justfile
    android-tools
    evolution-ews-core
    fish
    gnome-shell-extension-appindicator
    gnome-shell-extension-drive-menu
    gnome-shell-extension-launch-new-instance
    keepassxc
    podman-compose
    python3-pip
    wireguard-tools
)

# Install all Fedora packages (bulk - safe from COPR injection)
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf -y install "${FEDORA_PACKAGES[@]}"

# Packages to exclude - common to all versions
EXCLUDED_PACKAGES=(
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software
    gnome-software-rpm-ostree
    gnome-terminal-nautilus
    podman-docker
    yelp
)

# Remove excluded packages if they are installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

# Fix for ID in fwupd
dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap \
    --repo=copr:copr.fedorainfracloud.org:ublue-os:staging \
    fwupd fwupd

# TODO: remove me on next flatpak release when preinstall landed
dnf -y copr enable ublue-os/flatpak-test
dnf -y copr disable ublue-os/flatpak-test
dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
# print information about flatpak package, it should say from our copr
rpm -q flatpak --qf "%{NAME} %{VENDOR}\n" | grep ublue-os

tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo
dnf -y install --enablerepo=code \
    code

# Add Mutter experimental-features
MUTTER_EXP_FEATS="'scale-monitor-framebuffer', 'xwayland-native-scaling'"
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    MUTTER_EXP_FEATS="'kms-modifiers', ${MUTTER_EXP_FEATS}"
fi
tee /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override << EOF
[org.gnome.mutter]
experimental-features=[${MUTTER_EXP_FEATS}]
EOF

# Test bluefin gschema override for errors. If there are no errors, proceed with compiling bluefin gschema, which includes setting overrides.
mkdir -p /tmp/bluefin-schema-test
find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/bluefin-schema-test/ \;
cp /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override /tmp/bluefin-schema-test/
echo "Running error test for bluefin gschema override. Aborting if failed."
# We should ideally refactor this to handle multiple GNOME version schemas better
glib-compile-schemas --strict /tmp/bluefin-schema-test
echo "Compiling gschema to include bluefin setting overrides"
glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null
