#!/usr/bin/env bash
# Muse AI x Omarchy installer (user install, no sudo for launcher/CLI/plugin).
#   bash install.sh              CLI + launcher, then print the gadget step
#   bash install.sh launcher     CLI + launcher
#   bash install.sh gadget       CLI + gadget service (Meta's installer)
#   bash install.sh all          CLI + launcher + gadget service
#   bash install.sh plugin       CLI + bundled bar plugin
#   bash install.sh doctor       Run the preflight checks
#   bash install.sh uninstall    Remove the user launcher, icons, CLI, plugin
#   bash install.sh uninstall-gadget  Remove the gadget service
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$HOME/.local/bin/muse-ai"

ok()   { printf '  ok %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
fail() { printf '  x %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: bash install.sh [target] [options]

Targets:
  default           CLI + launcher (no sudo, no token)
  launcher          CLI + launcher
  gadget            CLI + Meta's gadget installer
  all               CLI + launcher + gadget
  plugin            CLI + bundled Omarchy bar plugin
  doctor            Run the preflight checks
  uninstall         Remove the user launcher, icons, CLI, and plugin
  uninstall-gadget  Remove the gadget service (add --purge for identity)

Options are forwarded to the CLI. For the gadget step:
  --accept-disclaimer   Non-interactive acceptance. Read SECURITY.md first.
  --yes, --no-pair      Forwarded to Meta's installer.
  --run-as USER         Forwarded to Meta's installer.
  --proxy URL           Forwarded to Meta's installer.
EOF
}

install_cli() {
  if [[ -e $CLI || -L $CLI ]]; then
    [[ -f $CLI && ! -L $CLI ]] &&
      grep -Eq '^# (OmaMetaMuse user CLI|muse-ai: Omarchy helper for Muse AI launcher)' "$CLI" ||
      fail "refusing to replace an unrelated CLI: $CLI"
  fi
  mkdir -p "$HOME/.local/bin"
  install -m755 "$REPO_DIR/bin/muse-ai" "$CLI"
  ok "CLI: $CLI"
  mkdir -p "$HOME/.local/share/muse-ai/plugin"
  cp -a "$REPO_DIR/plugin/." "$HOME/.local/share/muse-ai/plugin/"
  install -m644 "$REPO_DIR/SECURITY.md" "$REPO_DIR/DISCLAIMER.md" \
    "$REPO_DIR/share/applications/Muse.desktop" "$HOME/.local/share/muse-ai/"
  ok "plugin source: ~/.local/share/muse-ai/plugin"
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) warn "$HOME/.local/bin is not on PATH. Add: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
  local found
  found="$(command -v muse-ai 2>/dev/null || true)"
  if [[ -n $found && $found != "$CLI" ]]; then
    warn "muse-ai resolves to $found first; the user CLI may be shadowed"
  fi
}

run_cli() {
  MUSE_AI_NO_BANNER=1 "$CLI" "$@"
}

security_reminder() {
  echo "Security: the gadget service grants remote command access to this machine."
  echo "Read SECURITY.md and DISCLAIMER.md before installing it. Run: muse-ai security"
  echo
}

echo "OmaMetaMuse by WSTUNLTD"
security_reminder

target="${1:-default}"
if (( $# > 0 )); then
  shift
fi

case "$target" in
  default)
    install_cli
    run_cli launcher
    echo
    echo "Next, only when you are ready and on your own machine:"
    echo "  bash install.sh gadget"
    ;;
  launcher)
    install_cli
    run_cli launcher
    ;;
  gadget)
    MUSE_AI_NO_BANNER=1 bash "$REPO_DIR/bin/muse-ai" install-gadget "$@"
    install_cli
    ;;
  all)
    MUSE_AI_NO_BANNER=1 bash "$REPO_DIR/bin/muse-ai" install-gadget "$@"
    install_cli
    run_cli launcher
    ;;
  plugin)
    install_cli
    run_cli plugin-install "$@"
    ;;
  doctor)
    MUSE_AI_NO_BANNER=1 bash "$REPO_DIR/bin/muse-ai" doctor
    ;;
  uninstall)
    MUSE_AI_NO_BANNER=1 bash "$REPO_DIR/bin/muse-ai" uninstall "$@"
    ;;
  uninstall-gadget)
    MUSE_AI_NO_BANNER=1 bash "$REPO_DIR/bin/muse-ai" uninstall-gadget "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    fail "unknown target: $target (use: launcher | gadget | all | plugin | doctor | uninstall | uninstall-gadget)"
    ;;
esac
