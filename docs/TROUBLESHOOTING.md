# Troubleshooting

Start every diagnosis with:

```bash
muse-ai doctor
systemctl status musegadget --no-pager
journalctl -u musegadget -f
```

Read [SECURITY.md](../SECURITY.md) and [DISCLAIMER.md](../DISCLAIMER.md)
before installing or removing the gadget service.

## Token rejected: "that SDK token is not valid"

Make a fresh token at gadgets.muse.ai, Account, SDK tokens. Paste it
whole, on the machine itself, at Meta's hidden prompt. Common causes: a
placeholder was pasted, the token was copied with a trailing space or line
break, or the value was an API key from a different service. Tokens never
go in chat, in Git, or in an issue.

The wrapper no longer asks for the token. Meta's installer prompts with
echo disabled, so the token does not appear in `ps`. `MUSE_SDK_TOKEN` is
an explicit automation option; if you set it, the token is passed as an
argument and is visible to other local users while the installer runs.
Unset it afterwards.

## Installer refuses to run

It refuses root by design. Leave the root shell, open a normal terminal
as your daily user, and rerun.

## "Untested, Arch-based" warning

Expected on Omarchy. Omarchy is Arch based, the upstream installer has
a pacman path, and the warning is informational. Continue.

## The notice asks me to type INSTALL

That is the security gate. Read [SECURITY.md](../SECURITY.md) and
[DISCLAIMER.md](../DISCLAIMER.md), then type `INSTALL` exactly. For an
automated run, pass `--accept-disclaimer`; the wrapper refuses to download
anything in a non-interactive shell without it.

## No Bluetooth controller

```bash
ls /sys/class/bluetooth
systemctl status bluetooth --no-pager
bluetoothctl power on
bluetoothctl show
```

If there is still no controller, check that the hardware is not blocked
(`rfkill list`) and that firmware loaded (`dmesg | grep -i bluetooth`).
A USB Bluetooth dongle is the practical fallback on old machines.
Bluetooth is only needed for pairing. Once paired, network is enough.

## Pairing window expired

Pairing opens a short window after install. If you miss it, run
`sudo musegadget pair`, keep the phone close to the
machine, and pair right away in the app: Developer mode, Settings,
Devices.

## Launcher missing from the menu

```bash
muse-ai launcher
ls ~/.local/share/applications/Muse.desktop
```

Search the launcher for "Muse AI", not "Muse". If the icon looks
black or invisible, rerun `muse-ai launcher`: it re-renders the blue
icon and refreshes the icon cache. If it still looks wrong, run
`gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor` and reopen
the launcher. When `rsvg-convert` is missing, the fallback SVG lives at
`~/.local/share/icons/hicolor/scalable/apps/muse-ai.svg`.

## `muse-ai: command not found`

The user install puts the CLI in `~/.local/bin`. Add it to your shell:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

`bash install.sh` and `muse-ai doctor` both warn when that directory is
missing from `PATH`.

## Bar plugin does not respond to clicks

Install the bundled plugin from this repository, not an older copy:

```bash
muse-ai plugin-install --force
omarchy-shell shell rescanPlugins
```

The widget registers its root as a bar click target and exposes
`triggerPress(button)`, which is what the Omarchy 4 bar requires. Check
the IPC route with:

```bash
omarchy-shell io.github.microhustlestack.muse status
omarchy-shell io.github.microhustlestack.muse refresh
```

## Muse cannot see the machine after pairing

The machine must be awake and on the network. No terminal needs to stay
open. Check `muse-ai status` on the machine, confirm musegadget is
active, and confirm you are signed into the same Muse account in the
app and at muse.ai.

## Removing everything

```bash
muse-ai uninstall-gadget       # add --purge to delete identity and pairing
muse-ai uninstall              # launcher, icons, CLI, and bar plugin
```

The uninstall-gadget command asks you to type `UNINSTALL`, or accepts
`--accept-disclaimer` for automation. Then remove the device in the Muse
app and revoke the SDK token at gadgets.muse.ai.
