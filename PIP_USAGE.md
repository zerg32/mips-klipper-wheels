# Installing wheels from this repository

The Python wheels in this repository are built for MIPS architecture and are hosted on GitHub Pages as a PEP 503 compliant Python package index.

## Using pip

To install packages using these wheels, you can use pip with the following URL:

```bash
pip install --index-url https://zerg32.github.io/mips-klipper-wheels/wheels/simple/ <package-name>
```

Or to use it alongside PyPI:

```bash
pip install --extra-index-url https://zerg32.github.io/mips-klipper-wheels/wheels/simple/ <package-name>
```

## Configuring pip

To permanently configure pip to use this index, create or edit your pip configuration file:

### Linux/MacOS
Create or edit `~/.config/pip/pip.conf`:
```ini
[global]
extra-index-url = https://zerg32.github.io/mips-klipper-wheels/wheels/simple/
```

### Windows
Create or edit `%APPDATA%\pip\pip.ini`:
```ini
[global]
extra-index-url = https://zerg32.github.io/mips-klipper-wheels/wheels/simple/
```

### System-wide configuration (Linux)
Create or edit `/etc/pip.conf`:
```ini
[global]
extra-index-url = https://zerg32.github.io/mips-klipper-wheels/wheels/simple/
```

## Available Packages

You can browse all available packages at:
https://zerg32.github.io/mips-klipper-wheels/wheels/simple/

## Note

These wheels are specifically built for MIPS architecture and won't work on other architectures. Each wheel includes a SHA256 hash for verification.