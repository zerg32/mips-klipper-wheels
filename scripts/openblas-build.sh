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

# Patch debian/control to support mipsel
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*
# Check if architecture needs to be added
if ! grep -q "Architecture:.*any" debian/control && ! grep -q "Architecture:.*mipsel" debian/control; then
  echo "Patching debian/control to add mipsel support..."
  # Replace architecture with any for all packages
  sed -i "/^Package:/,/^$/s/^Architecture: .*/Architecture: any/" debian/control
fi
echo "=== debian/control architecture lines ==="
grep "^Architecture:" debian/control
'

# Install build dependencies for OpenBLAS
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*
apt build-dep -y openblas || apt install -y \
  gfortran \
  libblas-dev \
  liblapack-dev \
  cmake \
  pkg-config \
  debhelper
'

# Patch to use GENERIC target for MIPS
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*

echo "Forcing GENERIC target for MIPSEL build..."

# Create a simple patch to force GENERIC target
cat > debian/patches/force-generic-mips.patch <<EOF
Description: Force GENERIC target for MIPS architectures
 MIPS-specific optimizations are incomplete, use GENERIC target
Author: Build System
--- a/Makefile.system
+++ b/Makefile.system
@@ -1,3 +1,7 @@
+# Force GENERIC target for MIPS
+ifeq (\$(ARCH), mips)
+override TARGET = GENERIC
+endif
 # This is a generic Makefile
EOF

# Add to patch series if it exists
if [ -f debian/patches/series ]; then
  echo "force-generic-mips.patch" >> debian/patches/series
else
  mkdir -p debian/patches
  echo "force-generic-mips.patch" > debian/patches/series
fi
'

# Build the package
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*

echo "Building OpenBLAS for MIPSEL with GENERIC target..."
# Build with generic target, skip tests
export DEB_BUILD_OPTIONS="parallel=$(nproc) nocheck"
export TARGET=GENERIC
export DYNAMIC_ARCH=0

# Build binary packages only
dpkg-buildpackage -b -uc -us 2>&1 | tee /root/openblas-build/build.log

# Check if build was successful
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "Build failed. Check log for details."
  tail -n 100 /root/openblas-build/build.log
  exit 1
fi
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
