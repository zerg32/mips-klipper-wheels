#!/bin/bash
# shaketune-build.sh
# Script to build Klippain Shake&Tune wheels in MIPSEL chroot
set -e

# Set working directory
cd /mnt/mipsel-root

# Clone Klippain Shake&Tune source
chroot /mnt/mipsel-root git clone https://github.com/Frix-x/klippain-shaketune.git /klippain-shaketune

# Install required system packages
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y \
  python3-virtualenv python3-dev python3-numpy python3-matplotlib \
  libatlas-base-dev build-essential \
  gfortran liblapack-dev libblas-dev pkg-config \
  libssl-dev \
  libcurl4-openssl-dev \
  ca-certificates \
  autoconf automake libtool m4 gettext

# libopenblas-dev  - not available for MIPSEL

# Create wheels output directory
mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
chroot /mnt/mipsel-root python3 -m virtualenv /shaketune-venv

# Install build tools inside virtualenv
chroot /mnt/mipsel-root /shaketune-venv/bin/pip install --upgrade pip setuptools wheel build

# Build Klippain Shake&Tune and its dependencies into wheels
chroot /mnt/mipsel-root bash -c '
cd /klippain-shaketune
/shaketune-venv/bin/pip wheel -r requirements.txt -w /root/wheels'

# List built wheels
chroot /mnt/mipsel-root ls /root/wheels

echo "Klippain Shake&Tune wheels have been built in /mnt/mipsel-root/root/wheels"
