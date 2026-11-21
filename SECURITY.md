# Security notice and policy

OmaMetaMuse is a small community wrapper around Meta's official Muse
Gadgets Linux Device SDK. This document explains what the gadget service
can do, how this wrapper handles the SDK token, and how to report a
problem. Read it before you install the gadget service.

## The risk in one paragraph

The Muse gadget service lets Muse run commands on this machine and read or
write files as the configured account (the installer user by default). If that user has sudo, those
commands can use sudo too. Treat the service like a remote shell that you
deliberately leave running for your own Muse account. Install it only on a
machine you own and control. Never install it on a machine you sell, ship,
lend, or hand to someone else.

## Before you install

- Use a normal user account. The upstream installer refuses root.
- Read the upstream installer before running it. `muse-ai install-gadget`
  downloads it over HTTPS, checks its shell syntax, prints its SHA-256,
  saves a copy under `~/.cache/muse-ai/`, and offers to open it in `less`.
- Keep the machine awake and on a trusted network while it is paired.
- Remove the device from your Muse account if you stop using the machine,
  then remove the service with `muse-ai uninstall-gadget`.
- If you no longer trust the machine or the token, revoke the SDK token at
  gadgets.muse.ai and remove the service.

## SDK token handling

The SDK token starts with `mgst_` and is a secret. It grants access to your
Muse gadget account, so treat it like a password.

- Never commit a token, paste it into a chat or issue, or share a screenshot
  that contains one.
- Meta's installer prompts for the token on the terminal with echo disabled,
  then stores it root-only on this machine.
- This wrapper does not ask for the token and does not put it on a command
  line by default. Command-line arguments are visible to other local users
  through `ps`.
- `MUSE_SDK_TOKEN` is an explicit automation escape hatch. If you set it,
  the wrapper forwards it to the installer as an argument and prints a
  warning. Use it only on a machine where no other local user can watch the
  process table, and unset it afterwards.
- The wrapper stores only the security acknowledgment (notice version, UTC
  timestamp, hostname, and username) under
  `~/.local/state/muse-ai/security-ack`. It never stores the token.

## What this wrapper does

- Downloads Meta's installer from
  `https://raw.githubusercontent.com/facebookincubator/muse-gadget-sdk/main/linux/install.sh`
  using HTTPS with certificate and hostname verification. The URL tracks
  upstream `main`; the printed SHA-256 identifies the download, but is
  not a signature or proof that the script is safe.
- Runs `bash -n` on the download before executing it, prints the SHA-256,
  and keeps a review copy.
- Passes `--yes`, `--no-pair`, `--run-as`, and `--proxy` through to the
  official installer when you ask for them.
- Installs the launcher and bar plugin in your home directory only. The
  system package installs files under `/usr` and does not install the
  gadget service.
- Refuses to run the gadget step as root.

## What this wrapper does not do

- It does not audit, sandbox, or restrict what the gadget service or Muse
  can do after installation. That boundary belongs to Meta's SDK and your
  Muse account.
- It does not remove the device from your Muse account.
- It does not protect a machine from someone who already has your user
  account, your sudo access, or your Muse account.

## Supported versions

Security fixes are applied to the current `main` branch. The project does
not maintain older release branches.

## Reporting a vulnerability

Do not open a public issue for a token leak or an exploitable bug. Use
GitHub's private vulnerability reporting on
[github.com/microhustlestack/OmaMetaMuse](https://github.com/microhustlestack/OmaMetaMuse):
Security, then Report a vulnerability. Include the version, the affected
command or file, and reproduction steps. Never include a real `mgst_`
token, device identity, or personal data. Revoke any token you think was
exposed.

## Removing the service

```bash
muse-ai uninstall-gadget            # keeps device identity and pairing
muse-ai uninstall-gadget --purge    # deletes identity and pairing too
muse-ai uninstall                   # launcher, icons, CLI, and bar plugin
```

Then remove the device in the Muse app and revoke the SDK token at
gadgets.muse.ai if you are done with it.
