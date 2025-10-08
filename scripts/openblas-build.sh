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
  # Add mipsel to architecture list for all binary packages
  sed -i "s/Architecture: \(.*\)/Architecture: \1 mipsel/" debian/control
  # Or replace with any if too restrictive
  sed -i "s/Architecture: [a-z0-9 -]*/Architecture: any/" debian/control
fi
cat debian/control
'

# Patch source files to fix MIPS compilation issues
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*

# Fix missing GEMM_MULTITHREAD_THRESHOLD macro
echo "Patching source to fix GEMM_MULTITHREAD_THRESHOLD..."
find . -name "gemv.c" -o -name "gemm.c" | while read file; do
  if grep -q "GEMM_MULTITHREAD_THRESHOLD" "$file" && ! grep -q "#ifndef GEMM_MULTITHREAD_THRESHOLD" "$file"; then
    # Add default definition if not present
    sed -i "1i\\
#ifndef GEMM_MULTITHREAD_THRESHOLD\\
#define GEMM_MULTITHREAD_THRESHOLD 4\\
#endif" "$file"
    echo "Patched: $file"
  fi
done

# Alternative: patch the common.h or param.h if they exist
if [ -f common.h ]; then
  if ! grep -q "GEMM_MULTITHREAD_THRESHOLD" common.h; then
    echo "#ifndef GEMM_MULTITHREAD_THRESHOLD" >> common.h
    echo "#define GEMM_MULTITHREAD_THRESHOLD 4" >> common.h
    echo "#endif" >> common.h
  fi
fi
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

# Build the package
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/openblas-*

echo "Building OpenBLAS for MIPSEL..."
# Build with MIPS optimizations, skip tests, and set target
export DEB_BUILD_OPTIONS="parallel=$(nproc) nocheck"
export OPENBLAS_TARGET=MIPS24K
export OPENBLAS_DYNAMIC_ARCH=0
# Add CFLAGS to define missing macros
export DEB_CFLAGS_APPEND="-DGEMM_MULTITHREAD_THRESHOLD=4"

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
