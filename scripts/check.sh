#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> bash syntax"
for file in bin/muse-ai install.sh muse-ai-omarchy.install scripts/check.sh tests/cli.sh; do
  bash -n "$file"
done

echo "==> shellcheck"
if [[ -n ${SHELLCHECK:-} ]]; then
  "$SHELLCHECK" -S warning bin/muse-ai install.sh scripts/check.sh tests/cli.sh
elif command -v shellcheck >/dev/null 2>&1; then
  shellcheck -S warning bin/muse-ai install.sh scripts/check.sh tests/cli.sh
else
  echo "  shellcheck not found; skipping (CI installs it)"
fi

echo "==> manifest JSON"
python3 -m json.tool plugin/manifest.json >/dev/null

echo "==> desktop entry"
if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate share/applications/Muse.desktop
else
  echo "  desktop-file-validate not found; skipping"
fi

echo "==> Omarchy plugin validation"
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate plugin
else
  echo "  omarchy not found; skipping"
fi

echo "==> local documentation links"
python3 scripts/check-links.py

echo "==> CLI tests"
bash tests/cli.sh

echo "All checks passed."
