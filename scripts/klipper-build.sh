#!/bin/bash
# klipper-build.sh
# Script to build Klipper wheels in MIPSEL chroot
set -e

# Set working directory
cd /mnt/mipsel-root

# Clone Klipper source
chroot /mnt/mipsel-root git clone https://github.com/Klipper3d/klipper.git /klipper

# Extract and install packages from install-deps.sh
chroot /mnt/mipsel-root bash -c '
PKGS=$(grep -E "apt(-get)? install" /klipper/scripts/install-deps.sh | \
       sed -E "s/.*apt(-get)? install( --yes)?//g" | \
       tr -s " " "\n" | \
       grep -vE "^\s*$" | \
       sort -u | tr "\n" " ")
apt update
apt install -y $PKGS'

# Create wheels output directory
mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
chroot /mnt/mipsel-root python3 -m virtualenv /klipper-venv

# Install build tools inside virtualenv
chroot /mnt/mipsel-root /klipper-venv/bin/pip install --upgrade pip setuptools wheel build

# Build Klipper and its dependencies into wheels
chroot /mnt/mipsel-root bash -c '
cd /klipper
/klipper-venv/bin/pip wheel -r /klipper/scripts/klippy-requirements.txt -w /root/wheels'

# List built wheels
chroot /mnt/mipsel-root ls /root/wheels

echo "Klipper wheels have been built in /mnt/mipsel-root/root/wheels"