#!/bin/bash
# openblas-build.sh
# Script to build OpenBLAS from Debian source package for MIPSEL architecture
set -e

# Set working directory
cd /mnt/mipsel-root

# Enable source repositories
chroot /mnt/mipsel-root bash -c '
echo "deb-src http://deb.debian.org/debian bookworm main" >> /etc/apt/sources.list
'

# Install build dependencies
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y \
  build-essential \
  fakeroot \
  devscripts \
  dpkg-dev

# Create build directory
mkdir -p /mnt/mipsel-root/root/openblas-build
mkdir -p /mnt/mipsel-root/root/debs

# Download OpenBLAS source package
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build
apt source openblas
'

# Install build dependencies for OpenBLAS
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*
apt build-dep -y openblas || apt install -y \
  gfortran \
  libblas-dev \
  liblapack-dev \
  cmake \
  pkg-config
'

# Build the package
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*
# Build with MIPS-specific optimizations
DEB_BUILD_OPTIONS="parallel=$(nproc)" dpkg-buildpackage -b -uc -us
'

# Copy built packages to debs directory
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build
cp *.deb /root/debs/ 2>/dev/null || true
'

# List built packages
echo "Built Debian packages:"
chroot /mnt/mipsel-root ls -lh /root/debs/

echo "OpenBLAS Debian packages have been built in /mnt/mipsel-root/root/debs"
echo "You can install them with: chroot /mnt/mipsel-root dpkg -i /root/debs/libopenblas*.deb"
