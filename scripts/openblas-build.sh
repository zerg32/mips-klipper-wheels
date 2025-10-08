#!/bin/bash
# openblas-build.sh
# Script to build OpenBLAS from source for MIPSEL architecture
set -e

# Set working directory
cd /mnt/mipsel-root

# Install build dependencies
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y \
  build-essential \
  gfortran \
  cmake \
  git \
  debhelper \
  devscripts \
  fakeroot \
  dpkg-dev \
  pkg-config \
  libgfortran-11-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  ca-certificates

# Create build directory
mkdir -p /mnt/mipsel-root/root/openblas-build
mkdir -p /mnt/mipsel-root/root/debs

# Clone OpenBLAS source
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build
git clone --depth 1 https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS'

# Build OpenBLAS optimized for MIPS
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/OpenBLAS
# Use MIPS32 generic target for compatibility
make TARGET=MIPS32 DYNAMIC_ARCH=0 USE_THREAD=1 USE_OPENMP=0 \
     NO_LAPACK=0 NO_LAPACKE=0 NO_CBLAS=0 NO_AFFINITY=1 \
     PREFIX=/usr -j$(nproc)
'

# Install to a temporary location for packaging
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build/OpenBLAS
make PREFIX=/usr DESTDIR=/root/openblas-build/install install
'

# Create debian package structure
chroot /mnt/mipsel-root bash -c '
cd /root/openblas-build
mkdir -p openblas-package/DEBIAN
mkdir -p openblas-package/usr/lib
mkdir -p openblas-package/usr/include

# Copy libraries and headers
cp -r install/usr/lib/* openblas-package/usr/lib/
cp -r install/usr/include/* openblas-package/usr/include/

# Get OpenBLAS version
OPENBLAS_VERSION=$(grep "VERSION" OpenBLAS/Makefile.rule | head -1 | cut -d"=" -f2 | tr -d " ")
if [ -z "$OPENBLAS_VERSION" ]; then
  OPENBLAS_VERSION="0.3.27"
fi

# Create control file
cat > openblas-package/DEBIAN/control <<EOF
Package: libopenblas-dev
Version: ${OPENBLAS_VERSION}-mipsel
Section: libs
Priority: optional
Architecture: mipsel
Maintainer: MIPS Build <build@local>
Description: Optimized BLAS library for MIPSEL
 OpenBLAS is an optimized BLAS (Basic Linear Algebra Subprograms) library
 built from source for MIPSEL architecture.
 This package contains the development files.
Provides: libblas-dev, liblapack-dev
Conflicts: libopenblas-base, libopenblas-pthread-dev
EOF

# Build the package
dpkg-deb --build openblas-package /root/debs/libopenblas-dev_${OPENBLAS_VERSION}-mipsel.deb
'

# List built packages
echo "Built Debian packages:"
chroot /mnt/mipsel-root ls -lh /root/debs/

echo "OpenBLAS Debian package has been built in /mnt/mipsel-root/root/debs"
echo "You can install it with: chroot /mnt/mipsel-root dpkg -i /root/debs/libopenblas-dev_*.deb"
