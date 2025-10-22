#!/bin/bash
# klipperscreen-build.sh
# Script to build KlipperScreen wheels in MIPSEL chroot
set -e

# Set working directory
cd /mnt/mipsel-root

# Clone KlipperScreen source
chroot /mnt/mipsel-root git clone https://github.com/KlipperScreen/KlipperScreen.git /klipperscreen

# Install required system packages for KlipperScreen
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y \
  python3-virtualenv python3-dev \
  build-essential \
  libgirepository1.0-dev \
  libcairo2-dev \
  pkg-config \
  python3-gi python3-gi-cairo \
  gir1.2-gtk-3.0 \
  libpango1.0-dev \
  libglib2.0-dev \
  libffi-dev \
  libssl-dev \
  libdbus-1-dev \
  libdbus-glib-1-dev \
  libjpeg-dev \
  zlib1g-dev \
  libopenjp2-7 \
  libopenjp2-7-dev \
  libtiff-dev \
  libfreetype6-dev \
  liblcms2-dev \
  libwebp-dev \
  tcl8.6-dev \
  tk8.6-dev \
  python3-tk \
  librsvg2-dev \
  libgdk-pixbuf2.0-dev \
  libatlas-base-dev \
  gfortran \
  libsystemd-dev 

# Create wheels output directory
mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
chroot /mnt/mipsel-root python3 -m virtualenv /klipperscreen-venv

# Install build tools inside virtualenv
chroot /mnt/mipsel-root /klipperscreen-venv/bin/pip install --upgrade pip setuptools wheel build

# Build KlipperScreen and its dependencies into wheels
chroot /mnt/mipsel-root bash -c '
cd /klipperscreen
# Set environment variables for proper compilation
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/share/pkgconfig
export CFLAGS="-Wno-error"
export PYTHONWARNINGS="ignore::DeprecationWarning"

# Build the main requirements
if [ -f scripts/KlipperScreen-requirements.txt ]; then
  /klipperscreen-venv/bin/pip wheel -r scripts/KlipperScreen-requirements.txt -w /root/wheels
fi

# Also try the root requirements.txt if it exists
if [ -f requirements.txt ]; then
  /klipperscreen-venv/bin/pip wheel -r requirements.txt -w /root/wheels
fi

# List built wheels
chroot /mnt/mipsel-root ls /root/wheels

echo "KlipperScreen wheels have been built in /mnt/mipsel-root/root/wheels"
