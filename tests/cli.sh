#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/muse-ai-tests.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

export HOME="$WORK/home"
export TMPDIR="$WORK/tmp"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export PATH="$WORK/bin:$HOME/.local/bin:/usr/bin:/bin"
mkdir -p "$HOME" "$WORK/bin" "$TMPDIR"
unset MUSE_SDK_TOKEN MUSE_AI_NO_BANNER 2>/dev/null || true

pass() { printf '  ok %s\n' "$*"; }
die() { printf '  x %s\n' "$*" >&2; exit 1; }
assert_file() { [[ -f "$1" ]] || die "missing file: $1"; }
assert_exec() { [[ -x "$1" ]] || die "not executable: $1"; }
assert_missing() { [[ ! -e "$1" ]] || die "unexpected path: $1"; }
assert_contains() { grep -q -- "$2" "$1" || die "expected '$2' in $1"; }
assert_not_contains() {
  if grep -q -- "$2" "$1"; then
    die "unexpected '$2' in $1"
  fi
}

cat > "$WORK/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
out=""
prev=""
for arg in "$@"; do
  if [[ $prev == "-o" || $prev == "--output" ]]; then out=$arg; fi
  prev=$arg
done
url="${!#}"
if [[ -n ${FAKE_CURL_MARKER:-} ]]; then : > "$FAKE_CURL_MARKER"; fi
if [[ $url == *"muse.ai/images"* ]]; then
  cat > "$out" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="12" fill="#0b5cff"/>
</svg>
SVG
  exit 0
fi
if [[ $url == *"raw.githubusercontent.com"* && -n ${FAKE_UPSTREAM_INSTALLER:-} ]]; then
  cp "$FAKE_UPSTREAM_INSTALLER" "$out"
  exit 0
fi
printf 'unexpected curl: %s\n' "$url" >&2
exit 22
EOF
chmod +x "$WORK/bin/curl"

cat > "$WORK/upstream.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${FAKE_INSTALLER_ARGS:?}"
EOF
chmod +x "$WORK/upstream.sh"

cat > "$WORK/bin/omarchy" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'omarchy %s\n' "$*" >> "${FAKE_OMARCHY_LOG:?}"
if [[ ${1:-} == plugin && ${2:-} == remove ]]; then
  mv "$HOME/.config/omarchy/plugins/$3" "$HOME/.config/omarchy/plugins/.$3.removed"
fi
exit 0
EOF
chmod +x "$WORK/bin/omarchy"

cat > "$WORK/bin/omarchy-shell" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'omarchy-shell %s\n' "$*" >> "${FAKE_OMARCHY_LOG:?}"
exit 0
EOF
chmod +x "$WORK/bin/omarchy-shell"

echo "==> version and security output"
bash "$ROOT/bin/muse-ai" --version | grep -q '^muse-ai '
bash "$ROOT/bin/muse-ai" security > "$WORK/security.txt"
assert_contains "$WORK/security.txt" "Security notice and policy"
assert_contains "$WORK/security.txt" "Disclaimer"
pass "version and security"

echo "==> launcher install is idempotent"
MUSE_AI_NO_BANNER=1 bash "$ROOT/install.sh" launcher > "$WORK/install-1.log"
MUSE_AI_NO_BANNER=1 bash "$ROOT/install.sh" launcher > "$WORK/install-2.log"
assert_exec "$HOME/.local/bin/muse-ai"
assert_file "$HOME/.local/share/applications/Muse.desktop"
if [[ ! -f "$HOME/.local/share/icons/hicolor/256x256/apps/muse-ai.png" ]] \
  && [[ ! -f "$HOME/.local/share/icons/hicolor/scalable/apps/muse-ai.svg" ]]; then
  die "launcher icon was not installed"
fi
"$HOME/.local/bin/muse-ai" launcher >/dev/null
"$HOME/.local/bin/muse-ai" launcher >/dev/null
pass "install.sh launcher twice, muse-ai launcher twice"

echo "==> gadget gate fails before download"
rm -f "$WORK/curl-marker"
if HOME="$HOME" FAKE_CURL_MARKER="$WORK/curl-marker" \
  bash "$ROOT/bin/muse-ai" install-gadget </dev/null >/dev/null 2>&1; then
  die "install-gadget accepted a non-interactive run without --accept-disclaimer"
fi
assert_missing "$WORK/curl-marker"
for target in gadget all; do
  if HOME="$WORK/declined" XDG_STATE_HOME="$WORK/declined/state" FAKE_CURL_MARKER="$WORK/curl-marker" \
    bash "$ROOT/install.sh" "$target" </dev/null > "$WORK/declined.log" 2>&1; then
    die "$target accepted without acknowledgment"
  fi
  assert_contains "$WORK/declined.log" "non-interactive run"
  assert_missing "$WORK/declined"
  assert_missing "$WORK/curl-marker"
done
pass "non-interactive gadget install refused before download"

echo "==> gadget install keeps the token out of argv"
: > "$WORK/installer-args"
HOME="$HOME" \
  FAKE_INSTALLER_ARGS="$WORK/installer-args" \
  FAKE_UPSTREAM_INSTALLER="$WORK/upstream.sh" \
  bash "$ROOT/bin/muse-ai" install-gadget --accept-disclaimer --yes \
  > "$WORK/gadget-install.log" 2>&1
assert_file "$HOME/.local/state/muse-ai/security-ack"
assert_contains "$HOME/.local/state/muse-ai/security-ack" "notice_version="
assert_contains "$WORK/installer-args" "--yes"
assert_not_contains "$WORK/installer-args" "--sdk-token"
[[ -z $(find "$TMPDIR" -mindepth 1 -print -quit) ]] || die "temporary download was left behind"
[[ $(stat -c '%a' "$HOME/.local/state/muse-ai/security-ack") == 600 ]] || die "acknowledgment is not private"
if FAKE_CURL_MARKER="$WORK/curl-marker" bash "$ROOT/bin/muse-ai" install-gadget --yes \
  </dev/null >/dev/null 2>&1; then
  die "a previous acknowledgment or upstream --yes bypassed the gate"
fi
assert_missing "$WORK/curl-marker"
pass "default install-gadget does not pass --sdk-token"

echo "==> install.sh gadget installs the CLI"
: > "$WORK/installer-args-2"
HOME="$HOME" \
  FAKE_INSTALLER_ARGS="$WORK/installer-args-2" \
  FAKE_UPSTREAM_INSTALLER="$WORK/upstream.sh" \
  bash "$ROOT/install.sh" gadget --accept-disclaimer --yes \
  > "$WORK/gadget-install-2.log" 2>&1
assert_exec "$HOME/.local/bin/muse-ai"
assert_not_contains "$WORK/installer-args-2" "--sdk-token"
pass "install.sh gadget leaves muse-ai on PATH"

echo "==> explicit MUSE_SDK_TOKEN is the only argv path"
TOKEN="mgst_$(printf 'A%.0s' {1..42})E"
: > "$WORK/installer-args-3"
HOME="$HOME" \
  MUSE_SDK_TOKEN="$TOKEN" \
  FAKE_INSTALLER_ARGS="$WORK/installer-args-3" \
  FAKE_UPSTREAM_INSTALLER="$WORK/upstream.sh" \
  bash "$ROOT/bin/muse-ai" install-gadget --accept-disclaimer --yes \
  > "$WORK/gadget-install-3.log" 2>&1
assert_contains "$WORK/installer-args-3" "--sdk-token"
assert_contains "$WORK/installer-args-3" "$TOKEN"
assert_contains "$WORK/gadget-install-3.log" "visible in ps"
assert_not_contains "$WORK/gadget-install-3.log" "$TOKEN"
pass "MUSE_SDK_TOKEN is forwarded with a warning"

echo "==> gadget uninstall gate"
if FAKE_CURL_MARKER="$WORK/curl-marker" bash "$ROOT/bin/muse-ai" uninstall-gadget --yes </dev/null >/dev/null 2>&1; then
  die "uninstall-gadget accepted a non-interactive run without --accept-disclaimer"
fi
assert_missing "$WORK/curl-marker"
: > "$WORK/installer-args-4"
HOME="$HOME" \
  FAKE_INSTALLER_ARGS="$WORK/installer-args-4" \
  FAKE_UPSTREAM_INSTALLER="$WORK/upstream.sh" \
  bash "$ROOT/bin/muse-ai" uninstall-gadget --accept-disclaimer --purge \
  > "$WORK/gadget-uninstall.log" 2>&1
assert_contains "$WORK/installer-args-4" "--uninstall"
assert_contains "$WORK/installer-args-4" "--purge"
pass "uninstall-gadget requires UNINSTALL and forwards --purge"

echo "==> plugin install and removal"
: > "$WORK/omarchy.log"
FAKE_OMARCHY_LOG="$WORK/omarchy.log" \
  bash "$HOME/.local/bin/muse-ai" plugin-install > "$WORK/plugin-install.log"
assert_file "$HOME/.config/omarchy/plugins/io.github.microhustlestack.muse/manifest.json"
assert_contains "$WORK/omarchy.log" "plugin enable io.github.microhustlestack.muse"
if FAKE_OMARCHY_LOG="$WORK/omarchy.log" \
  bash "$HOME/.local/bin/muse-ai" plugin-install >/dev/null 2>&1; then
  die "plugin-install replaced an existing plugin without --force"
fi
FAKE_OMARCHY_LOG="$WORK/omarchy.log" \
  bash "$HOME/.local/bin/muse-ai" plugin-install --force > "$WORK/plugin-force.log"
FAKE_OMARCHY_LOG="$WORK/omarchy.log" \
  bash "$HOME/.local/bin/muse-ai" plugin-remove --yes > "$WORK/plugin-remove.log"
assert_missing "$HOME/.config/omarchy/plugins/io.github.microhustlestack.muse"
pass "plugin install, force replace, and remove"

echo "==> user uninstall removes launcher, icons, CLI, and plugin"
bash "$HOME/.local/bin/muse-ai" uninstall > "$WORK/uninstall.log"
assert_missing "$HOME/.local/share/applications/Muse.desktop"
assert_missing "$HOME/.local/bin/muse-ai"
assert_missing "$HOME/.local/share/icons/hicolor/256x256/apps/muse-ai.png"
assert_missing "$HOME/.local/share/icons/hicolor/scalable/apps/muse-ai.svg"
assert_missing "$HOME/.local/share/icons/muse-ai.svg"
pass "user uninstall cleans the user install"

echo "==> uninstall leaves a foreign muse-ai alone"
mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\necho foreign\n' > "$HOME/.local/bin/muse-ai"
chmod +x "$HOME/.local/bin/muse-ai"
bash "$ROOT/bin/muse-ai" uninstall > "$WORK/uninstall-foreign.log" 2>&1
assert_file "$HOME/.local/bin/muse-ai"
assert_contains "$WORK/uninstall-foreign.log" "not an OmaMetaMuse user install"
pass "foreign CLI is not deleted"

echo "All CLI tests passed."
