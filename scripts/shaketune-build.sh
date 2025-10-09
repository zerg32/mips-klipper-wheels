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
  autoconf automake libtool m4 gettext \
  cmake \
  ninja-build \
  libffi-dev \
  libxml2-dev \
  libxslt1-dev \
  zlib1g-dev \
  libjpeg-dev \
  libpng-dev \
  libfreetype6-dev

# Install GitHub CLI if not available
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt update
    apt install gh -y
    echo "GitHub CLI installed successfully"
else
    echo "GitHub CLI is already installed"
fi

# Download and install OpenBLAS from latest successful build
echo "Attempting to download OpenBLAS packages from latest build..."
mkdir -p /tmp/openblas-download

echo "Using GitHub CLI to download OpenBLAS artifacts..."
cd /tmp/openblas-download

# Ensure GitHub CLI is authenticated
if ! gh auth status &>/dev/null; then
    echo "GitHub CLI not authenticated. Attempting to authenticate..."
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | gh auth login --with-token
    else
        echo "Error: GITHUB_TOKEN environment variable not set"
        echo "Please set GITHUB_TOKEN or run 'gh auth login' manually"
        exit 1
    fi
fi

gh run download --repo zerg32/mips-klipper-wheels --name libopenblas-dev-mipsel 
echo "Successfully downloaded OpenBLAS artifacts"
echo "Available .deb files:"
ls -la *.deb 2>/dev/null || echo "No .deb files found"

mkdir -p /mnt/mipsel-root/root/debs
cp *.deb /mnt/mipsel-root/root/debs/ 2>/dev/null || echo "No .deb files found in artifacts"
cd -

echo "Copied .deb files to chroot:"
chroot /mnt/mipsel-root ls -la /root/debs/ 2>/dev/null || echo "No files in /root/debs"
  

# Install custom OpenBLAS if available (better performance than ATLAS)
if [ -f /mnt/mipsel-root/root/debs/libopenblas-dev_*.deb ]; then
  echo "Installing custom OpenBLAS packages in correct order..."
  
  # Install base library first
  chroot /mnt/mipsel-root bash -c 'cd /root/debs && dpkg -i libopenblas0_*.deb || apt-get install -f -y'
  
  # Install pthread variant
  chroot /mnt/mipsel-root bash -c 'cd /root/debs && dpkg -i libopenblas0-pthread_*.deb || apt-get install -f -y'
  
  # Install development headers for pthread variant
  chroot /mnt/mipsel-root bash -c 'cd /root/debs && dpkg -i libopenblas-pthread-dev_*.deb || apt-get install -f -y'
  
  # Install main development package (depends on libopenblas0)
  chroot /mnt/mipsel-root bash -c 'cd /root/debs && dpkg -i libopenblas-dev_*.deb || apt-get install -f -y'
  
  # Fix any remaining dependency issues
  chroot /mnt/mipsel-root apt-get install -f -y
else
  echo "Using ATLAS BLAS (OpenBLAS not available)"
fi

# Cleanup
rm -rf /tmp/openblas-download

# Create wheels output directory
mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
chroot /mnt/mipsel-root python3 -m virtualenv /shaketune-venv

# Install build tools inside virtualenv
chroot /mnt/mipsel-root /shaketune-venv/bin/pip install --upgrade pip setuptools wheel build

# Install build dependencies for numpy/scipy (except pythran which needs numpy)
chroot /mnt/mipsel-root /shaketune-venv/bin/pip install \
  "Cython>=0.29.32,<3.0" \
  pybind11 \
  meson-python \
  pkgconfig

# Build Klippain Shake&Tune and its dependencies into wheels
chroot /mnt/mipsel-root bash -c '
cd /klippain-shaketune
# Ensure the virtualenv Cython is in PATH (newer version than system)
export PATH=/shaketune-venv/bin:$PATH
# Set environment variables for proper compilation
export NPY_NUM_BUILD_JOBS=1
export CFLAGS="-Wno-error"
# Build numpy first (scipy depends on it) - use a version compatible with Python 3.11
/shaketune-venv/bin/pip wheel numpy==1.24.4 -w /root/wheels --no-build-isolation
# Install the built numpy wheel to make it available for pythran
NUMPY_WHEEL=$(ls /root/wheels/numpy-1.24.4*.whl | head -n1)
/shaketune-venv/bin/pip install "$NUMPY_WHEEL"
# Now install pythran with the correct numpy version
/shaketune-venv/bin/pip install pythran
# Then build scipy - use compatible version
/shaketune-venv/bin/pip wheel scipy==1.10.1 -w /root/wheels --no-build-isolation
# Build other requirements if they exist
if [ -f requirements.txt ]; then
  /shaketune-venv/bin/pip wheel -r requirements.txt -w /root/wheels
fi'

# /shaketune-venv/bin/pip wheel -r requirements.txt -w /root/wheels'

# List built wheels
chroot /mnt/mipsel-root ls /root/wheels

echo "Klippain Shake&Tune wheels have been built in /mnt/mipsel-root/root/wheels"
