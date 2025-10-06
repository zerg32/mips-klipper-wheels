# MIPS Python Wheels Builder

This repository contains scripts and workflows to build Python wheels for MIPS architecture, specifically targeting Klipper and Moonraker installations on MIPS-based systems.

## Overview

The project uses GitHub Actions to create a MIPS (little-endian) chroot environment where Python packages are compiled into wheels. These wheels are then published to GitHub Pages as a PEP 503 compliant Python package index.

## Scripts Overview

### Setup Scripts

- **make-scripts-executable.sh**: Simple utility script that makes all scripts in the `scripts/` directory executable
- **scripts/chroot-setup.sh**: Sets up a MIPSEL chroot environment using Debian Bookworm as the base system
- **scripts/builder-setup.sh**: Installs necessary build dependencies inside the chroot environment

### Build Scripts

- **scripts/klipper-build.sh**: Clones Klipper repository and builds wheels for Klipper and its dependencies
- **scripts/moonraker-build.sh**: Clones Moonraker repository and builds wheels for Moonraker and its dependencies
- **scripts/generate-index.sh**: Creates a PEP 503 compliant package index from the built wheels

## How It Works

1. **Environment Setup**:
   - Creates a MIPSEL chroot environment using Debian Bookworm
   - Sets up QEMU for MIPS emulation
   - Installs necessary build tools and dependencies

2. **Build Process**:
   - Clones target repositories (Klipper/Moonraker)
   - Creates Python virtual environments
   - Builds wheels for the main packages and their dependencies
   - Stores wheels in `/mnt/mipsel-root/root/wheels`

3. **Publishing**:
   - Generates a PEP 503 compliant package index
   - Deploys wheels and index to GitHub Pages
   - Makes packages available through a pip-compatible URL

## Usage

See [PIP_USAGE.md](PIP_USAGE.md) for detailed instructions on how to use these wheels in your MIPS system.

## GitHub Actions Workflow

The [build-wheels.yml](.github/workflows/build-wheels.yml) workflow:
1. Sets up a Ubuntu runner
2. Creates a MIPSEL chroot environment
3. Builds Python wheels for specified packages
4. Publishes wheels to GitHub Pages
5. Generates and deploys a PEP 503 compatible package index

## License

This project is licensed under the [MIT License](LICENSE).