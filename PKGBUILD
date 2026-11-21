# Maintainer: J'Juan Wilson Jr. <hello@microhustlestack.com>
pkgname=muse-ai-omarchy-git
pkgver=0.2.0.r0.g0000000
pkgrel=1
pkgdesc="OmaMetaMuse by WSTUNLTD: Muse AI launcher plus a safe wrapper for Meta's official Muse Gadgets SDK on Omarchy"
arch=('any')
url="https://github.com/microhustlestack/OmaMetaMuse"
license=('MIT')
depends=('bash' 'curl')
makedepends=('git')
checkdepends=('python' 'desktop-file-utils')
optdepends=(
  'librsvg: render the Muse icon to PNG sizes at launcher install'
  'bluez: Bluetooth, needed for the gadget pairing window only'
)
provides=('muse-ai')
conflicts=('muse-ai')
source=("git+$url.git")
sha256sums=('SKIP')
install=muse-ai-omarchy.install

pkgver() {
  cd "$srcdir/OmaMetaMuse"
  printf "%s.r%s.g%s" "0.2.0" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

check() {
  cd "$srcdir/OmaMetaMuse"
  bash -n bin/muse-ai
  bash -n install.sh
  python3 -m json.tool plugin/manifest.json >/dev/null
  desktop-file-validate share/applications/Muse.desktop
  bash tests/cli.sh
}

package() {
  cd "$srcdir/OmaMetaMuse"
  install -Dm755 bin/muse-ai "$pkgdir/usr/bin/muse-ai"
  install -Dm644 share/applications/Muse.desktop "$pkgdir/usr/share/applications/Muse.desktop"
  install -Dm644 share/applications/Muse.desktop "$pkgdir/usr/share/muse-ai-omarchy/Muse.desktop"

  install -Dm644 plugin/BarWidget.qml "$pkgdir/usr/share/muse-ai-omarchy/plugin/BarWidget.qml"
  install -Dm644 plugin/manifest.json "$pkgdir/usr/share/muse-ai-omarchy/plugin/manifest.json"
  install -Dm644 plugin/README.md "$pkgdir/usr/share/muse-ai-omarchy/plugin/README.md"
  install -Dm644 plugin/LICENSE "$pkgdir/usr/share/muse-ai-omarchy/plugin/LICENSE"

  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm644 SECURITY.md "$pkgdir/usr/share/doc/$pkgname/SECURITY.md"
  install -Dm644 DISCLAIMER.md "$pkgdir/usr/share/doc/$pkgname/DISCLAIMER.md"
  install -Dm644 -t "$pkgdir/usr/share/doc/$pkgname/docs" docs/*.md docs/*.webp docs/omametamuse-header.png
  install -Dm644 -t "$pkgdir/usr/share/doc/$pkgname/plugin" plugin/README.md plugin/LICENSE
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
