#!/usr/bin/env bash
# Muse Ai x Omarchy installer (user install, no sudo for launcher/CLI).
#   bash install.sh            launcher + CLI into ~/.local, gadget step printed only
#   bash install.sh launcher   launcher only
#   bash install.sh gadget     gadget service only (Meta's official installer)
#   bash install.sh all        launcher + CLI + gadget
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_cli_launcher() {
  mkdir -p "$HOME/.local/bin"
  install -m755 "$REPO_DIR/bin/muse-ai" "$HOME/.local/bin/muse-ai"
  echo "  ok CLI: ~/.local/bin/muse-ai"
  "$HOME/.local/bin/muse-ai" launcher
}

echo "OmaMetaMuse by WSTUNLTD"
target="${1:-default}"
case "$target" in
  launcher) bash "$REPO_DIR/bin/muse-ai" launcher ;;
  gadget)   bash "$REPO_DIR/bin/muse-ai" install-gadget ;;
  all)      install_cli_launcher; "$HOME/.local/bin/muse-ai" install-gadget ;;
  default)  install_cli_launcher; echo; echo "Next, only when you are ready and on your own machine:"; echo "  bash install.sh gadget" ;;
  *) echo "unknown target: $target (use: launcher | gadget | all)" >&2; exit 1 ;;
esac
