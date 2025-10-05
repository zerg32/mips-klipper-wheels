FROM mipsel-chroot-builder

# Set working directory
WORKDIR /mnt/mipsel-root

# Clone Klipper source
RUN chroot /mnt/mipsel-root git clone https://github.com/Klipper3d/klipper.git /klipper

# Extract and install packages from install-deps.sh
RUN chroot /mnt/mipsel-root bash -c "\
  PKGS=$(grep -E 'apt(-get)? install' /klipper/scripts/install-deps.sh | \
         sed -E 's/.*apt(-get)? install( --yes)?//g' | \
         tr -s ' ' '\n' | \
         grep -vE '^\s*$' | \
         sort -u | tr '\n' ' ') && \
  apt update && \
  apt install -y \$PKGS \
"

# Create wheels output directory
RUN mkdir -p /mnt/mipsel-root/root/wheels

# Create and activate virtualenv
RUN chroot /mnt/mipsel-root python3 -m virtualenv /klipper-venv

# Install build tools inside virtualenv
RUN chroot /mnt/mipsel-root /klipper-venv/bin/pip install --upgrade pip setuptools wheel build

# Build Moonraker and its dependencies into wheels
RUN chroot /mnt/mipsel-root bash -c "\
  cd /klipper && \
  /klipper-venv/bin/pip wheel -r /klipper/scripts/klippy-requirements.txt -w /root/wheels \
"
#   /klipper-venv/bin/pip wheel . -w /root/wheels && \

# Optional: list built wheels
RUN chroot /mnt/mipsel-root ls /root/wheels
