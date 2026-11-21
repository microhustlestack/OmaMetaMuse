# Muse for Omarchy (plugin)

A bar widget for [Omarchy](https://omarchy.org) 4 (Quattro) that shows whether this machine is linked to [Muse](https://muse.ai), and launches Muse when you click it.

The widget watches the Muse gadget service (`musegadget.service`, from Meta's official Muse Gadgets SDK) and shows its state as a status dot next to the Muse icon in the bar:

- Green: the gadget service is active, this machine is linked to Muse
- Red: the service is installed but not running, or the check failed
- Grey: still checking

It is the companion plugin to [OmaMetaMuse by WSTUNLTD](https://github.com/microhustlestack/OmaMetaMuse), the package that installs the Muse launcher and the safe gadget wrapper on Omarchy. The widget lives in that repository under `plugin/` and is installed from there.

## Install

From a clone of OmaMetaMuse, install the CLI first if you have not already:

```bash
bash install.sh launcher
muse-ai plugin-install
```

`plugin-install` copies this folder to `~/.config/omarchy/plugins/io.github.microhustlestack.muse/`, runs the shell plugin rescan, and enables the widget. It lands in the right section of the bar by default; move it with `omarchy bar move io.github.microhustlestack.muse` or by dragging.

Manual install:

```bash
mkdir -p ~/.config/omarchy/plugins/io.github.microhustlestack.muse
cp -r plugin/. ~/.config/omarchy/plugins/io.github.microhustlestack.muse/
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.microhustlestack.muse
```

If you already have an older copy installed, `muse-ai plugin-install --force` backs it up before replacing it.

## Remove

```bash
muse-ai plugin-remove
```

Manual removal: disable it first (`omarchy plugin disable io.github.microhustlestack.muse`), then delete `~/.config/omarchy/plugins/io.github.microhustlestack.muse/`. The widget writes no configuration of its own; its settings live inline in `~/.config/omarchy/shell.json` and are removed with the plugin entry.

## Dependencies

- Omarchy 4 (Quattro) with the shell plugin system. The widget uses only the standard plugin APIs (`qs.Ui` BarWidget, Quickshell Process, Widgets and IPC).
- Optional, for a green dot: the `musegadget.service` systemd unit from Meta's Muse Gadgets SDK, installed and running on this machine. The [OmaMetaMuse package](https://github.com/microhustlestack/OmaMetaMuse) sets that up safely on your own studio or personal machines. Without it the widget still installs and simply reports the service as not active.
- Click to launch uses Omarchy's built-in `omarchy-launch-webapp`, which opens muse.ai as a webapp. Change the launch command in the widget settings if you launch Muse another way.

## Settings

Set inline on the widget's entry in `~/.config/omarchy/shell.json`, or through the bar's widget options:

| Key | Default | What it does |
| --- | --- | --- |
| `iconName` | `muse-ai` | Themed icon shown next to the status dot |
| `label` | `Muse` | Text shown when the label is on, or as a fallback if the icon is missing |
| `showLabel` | `false` | On adds the text label next to the icon |
| `refreshSeconds` | `30` | How often the gadget service state is checked (5 to 300) |
| `serviceName` | `musegadget.service` | systemd unit that links this machine to Muse |
| `launchCommand` | `omarchy-launch-webapp https://muse.ai/` | Command run when the widget is clicked |

## IPC

```bash
omarchy-shell io.github.microhustlestack.muse status    # prints the service state
omarchy-shell io.github.microhustlestack.muse refresh   # re-check every monitor now
omarchy-shell io.github.microhustlestack.muse launch    # run the launch command
```

Left click launches Muse; middle click refreshes the status.

## Safety note

The gadget service gives Muse access to the machine it runs on. Run it only on machines you own and control, never on a machine you sell or hand to someone else. Read [SECURITY.md](../SECURITY.md) and [DISCLAIMER.md](../DISCLAIMER.md) in the checkout, or run `muse-ai security`. This widget only reads the service state with `systemctl is-active` and runs the launch command you configure; it does not install or control the service. Set `launchCommand` only to a shell command you trust.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 J'Juan Wilson Jr. / Micro Hustle Stack.
