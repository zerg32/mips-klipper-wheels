FROM debian:bookworm

# Install required tools
RUN apt update && apt install -y \
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
  #chroot \
  curl \
  ca-certificates

# Create MIPSEL rootfs directory
RUN mkdir -p /mnt/mipsel-root

# Bootstrap Debian Bookworm for MIPSEL (foreign stage)
RUN debootstrap --arch=mipsel --foreign bookworm /mnt/mipsel-root http://deb.debian.org/debian

# Copy QEMU binary into rootfs
RUN cp /usr/bin/qemu-mipsel-static /mnt/mipsel-root/usr/bin/

# Complete second stage of debootstrap
RUN chroot /mnt/mipsel-root /debootstrap/debootstrap --second-stage

# Optional: Add a user inside chroot
RUN chroot /mnt/mipsel-root useradd -m -s /bin/bash mipsuser && \
    echo "mipsuser:mips" | chroot /mnt/mipsel-root chpasswd

# Set working directory
WORKDIR /mnt/mipsel-root

# Default command: enter chroot
CMD ["chroot", "/mnt/mipsel-root", "/bin/bash"]