#!/bin/bash
# builder-setup.sh
# Script to set up build environment in MIPSEL chroot
set -e

# Install build packages inside the chroot
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y \
    git \
    pkg-config \
    unzip \
    gcc-arm-none-eabi \
    libusb-dev \
    libffi-dev \
    build-essential \
    avr-libc \
    binutils-avr \
    wget \
    gcc-avr \
    virtualenv \
    libnewlib-arm-none-eabi \
    avrdude \
    stm32flash \
    dfu-util \
    python3-virtualenv \
    libncurses-dev \
    binutils-arm-none-eabi \
    libusb-1.0-0-dev \
    python3-dev 

# Ensure virtualenv is installed
chroot /mnt/mipsel-root apt update
chroot /mnt/mipsel-root apt install -y python3-virtualenv

echo "Build environment setup complete in MIPSEL chroot"