#!/bin/bash
# chroot-setup.sh
# Script to set up MIPSEL chroot environment
set -e

# Install required tools
apt update && apt install -y \
  qemu-user-static \
  binfmt-support \
  debootstrap \
  sudo \
  gnupg \
  systemd \
  procps \
  iproute2 \
  net-tools \
  nano \
  bash \
  curl \
  ca-certificates

# Enable QEMU MIPS
update-binfmts --enable qemu-mipsel

# Create MIPSEL rootfs directory
mkdir -p /mnt/mipsel-root

# Bootstrap Debian Bookworm for MIPSEL (foreign stage)
debootstrap --arch=mipsel --foreign bookworm /mnt/mipsel-root http://deb.debian.org/debian

# Copy QEMU binary into rootfs
cp /usr/bin/qemu-mipsel-static /mnt/mipsel-root/usr/bin/

# Complete second stage of debootstrap
chroot /mnt/mipsel-root /debootstrap/debootstrap --second-stage

# Add a user inside chroot
chroot /mnt/mipsel-root useradd -m -s /bin/bash mipsuser
echo "mipsuser:mips" | chroot /mnt/mipsel-root chpasswd

echo "MIPSEL chroot environment is ready at /mnt/mipsel-root"