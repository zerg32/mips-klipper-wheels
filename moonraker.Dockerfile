FROM mipsel-chroot-builder

# Set working directory
WORKDIR /mnt/mipsel-root

# Clone Moonraker source
RUN chroot  /mnt/mipsel-root git clone https://github.com/Arksine/moonraker.git /moonraker

RUN chroot /mnt/mipsel-root apt update && \
    chroot /mnt/mipsel-root apt install -y \
      python3-virtualenv python3-dev libopenjp2-7 \
      libsodium-dev zlib1g-dev libjpeg-dev packagekit \
      wireless-tools curl build-essential


# Create wheels output directory
RUN mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
RUN chroot /mnt/mipsel-root python3 -m virtualenv /moonraker-venv

# Install build tools inside virtualenv
RUN chroot /mnt/mipsel-root /moonraker-venv/bin/pip install --upgrade pip setuptools wheel build

# Build Moonraker and its dependencies into wheels
RUN chroot /mnt/mipsel-root bash -c "\
  cd /moonraker && \
  /moonraker-venv/bin/pip wheel . -w /root/wheels && \
  /moonraker-venv/bin/pip wheel -r scripts/moonraker-requirements.txt -w /root/wheels \
"

# Optional: list built wheels
RUN chroot /mnt/mipsel-root ls /root/wheels
