# Tested hardware and test log

## First install: MacBook Air 11-inch, Mid 2011

Date: October 22, 2026. Project: OmaMetaMuse by WSTUNLTD.

Machine, as read on device:

- Intel Core i5-2467M at 2.30 GHz, 2nd Gen Intel integrated graphics
- 1366x768 built in display
- RAM: 4 GB total (3.73 GiB reported)
- Disk: 128 GB SSD, 110.98 GiB total, btrfs
- OS: Omarchy 4.0.6-1, stable
- Kernel: Linux 7.2.8-9-omarchy
- Desktop: Hyprland 0.56.2 (Wayland), foot 1.28.0
- No T2 chip

Preflight, passed:

- `uname -m` printed x86_64
- Bluetooth controller present at hci0, Powered: yes, Pairable: yes,
  roles central and peripheral, advertising supported
- bluetooth.service active

Install timeline:

1. First attempt failed at token validation. Cause: a placeholder
   token was pasted instead of a real one. No install completed, and
   rerunning was safe. Lesson, now built into the CLI: the token is
   checked for the `mgst_` prefix before the installer runs.
2. Second attempt with a fresh real token succeeded. The upstream
   installer pulled its pacman packages, set up its Python environment,
   adjusted BlueZ for pairing, saved the token on device only, and
   installed the musegadget systemd service.
3. Pairing completed inside the window: app consent, Wi-Fi provision,
   authentication, setup complete.
4. Verification from Muse chat passed: device listed online with 4
   commands (system.run, file.read, file.write, device.health).
   Health reported temperature 32.4 C, about 1.7 GB memory available of
   3.8 GB, about 86 GB disk free of 119 GB, uptime about 2.6 days.
   A command test as the install user returned the correct username,
   hostname, x86_64, and musegadget active, exit 0.

Launcher, same day:

- Created `~/.local/share/applications/Muse.desktop` following the
  machine's existing webapp entries, Name set to Muse AI on request.
- Icon: official blue Muse squiggle. The final working setup renders
  the official SVG to PNG with rsvg-convert and installs it as
  `muse-ai` at 256, 128, 64, 48, and 32 px under
  `~/.local/share/icons/hicolor/`. The 256 px render was verified on
  device as the Muse blue, and the owner confirmed on device:
  "It's blue now."
- That icon method is what `muse-ai launcher` automates in this repo.

Same machine, other proof: this Air also built and ran the
WSTUNLTD™ Second Brain Omarchy package end to end on the same day,
which is why it is this project's reference machine.

## Add your machine

Tested on something else? Open an issue or a pull request with: machine,
CPU, RAM, Omarchy version, Bluetooth check result, and whether pairing
and the health check passed. No tokens, no node IDs, no personal data.
