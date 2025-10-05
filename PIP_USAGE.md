# Installing wheels from this repository

The Python wheels in this repository are built for MIPS architecture and are hosted on GitHub Pages.

## Using pip

To install packages using these wheels, you can use pip with the following URL:

```bash
pip install --extra-index-url https://zerg32.github.io/mips-klipper-wheels/wheels/ <package-name>
```

Or add this to your `pip.conf` or `pip.ini`:

```ini
[global]
extra-index-url = https://zerg32.github.io/mips-klipper-wheels/wheels/
```

## Available Packages

You can browse all available wheels at:
https://zerg32.github.io/mips-klipper-wheels/wheels/

## Note

These wheels are specifically built for MIPS architecture and won't work on other architectures.