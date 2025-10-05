# Klipper & friends MIPSEL Build Environment (Docker-Based)

This project sets up a Docker-based cross-architecture build environment for MIPSEL using QEMU and Debian Bookworm. It builds Python wheels for [Moonraker](https://github.com/Arksine/moonraker) inside a chrooted virtualenv.

---

## Prerequisites

- Docker installed on your host system
- WSL2 or Linux environment (recommended for USB passthrough)
- Internet access for package downloads

---

## Step-by-Step Build Instructions

### 1. Base Chroot Environment

Build the base container with a Debian Bookworm MIPSEL chroot using QEMU:

```bash
docker build -t mipsel-chroot -f chroot.Dockerfile .
```

### 2. Builder container

Build the builder container that has all the required debian packages in chroot environment

```bash
docker build -t mipsel-chroot-builder -f chroot.Dockerfile .
```

### 3. Moonraker container

Clone moonraker and build all the required python wheels

```bash
docker build -t mipsel-chroot-moonraker -f moonraker.Dockerfile .
docker create --name moonraker-container moonraker-wheels
docker cp moonraker-container:/mnt/mipsel-root/root/wheels/ ./gh-pages
docker rm moonraker-container
```

### 4. Klipper container

Clone moonraker and build all the required python wheels

```bash
docker build -t mipsel-chroot-klipper -f klipper.Dockerfile .
docker create --name klipper-container klipper-wheels
docker cp klipper-container:/mnt/mipsel-root/root/wheels/ ./gh-pages
docker rm klipper-container

```