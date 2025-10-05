#!/bin/bash
# moonraker-build.sh
# Script to build Moonraker wheels in MIPSEL chroot
set -e

# Set working directory
cd /mnt/mipsel-root

# Clone Moonraker source
chroot /mnt/mipsel-root git clone https://github.com/Arksine/moonraker.git /moonraker

# Install required packages
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y \
  python3-virtualenv python3-dev libopenjp2-7 \
  libsodium-dev zlib1g-dev libjpeg-dev packagekit \
  wireless-tools curl build-essential

# Create wheels output directory
mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
chroot /mnt/mipsel-root python3 -m virtualenv /moonraker-venv

# Install build tools inside virtualenv
chroot /mnt/mipsel-root /moonraker-venv/bin/pip install --upgrade pip setuptools wheel build

# Build Moonraker and its dependencies into wheels
chroot /mnt/mipsel-root bash -c '
cd /moonraker
/moonraker-venv/bin/pip wheel . -w /root/wheels
/moonraker-venv/bin/pip wheel -r scripts/moonraker-requirements.txt -w /root/wheels'

# List built wheels
chroot /mnt/mipsel-root ls /root/wheels

echo "Moonraker wheels have been built in /mnt/mipsel-root/root/wheels"