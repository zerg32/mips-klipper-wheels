#!/bin/bash
# install-openblas.sh
# Script to install custom-built OpenBLAS package in MIPSEL chroot
set -e

# Set working directory
cd /mnt/mipsel-root

# Check if OpenBLAS package exists
if [ ! -f /mnt/mipsel-root/root/debs/libopenblas-dev_*.deb ]; then
  echo "Error: OpenBLAS package not found in /mnt/mipsel-root/root/debs/"
  echo "Please run openblas-build.sh first to build the package."
  exit 1
fi

echo "Installing custom-built OpenBLAS package..."

# Install the package
chroot /mnt/mipsel-root bash -c '
cd /root/debs
dpkg -i libopenblas-dev_*.deb || apt-get install -f -y
'

echo "OpenBLAS package installed successfully!"
chroot /mnt/mipsel-root dpkg -l | grep openblas
