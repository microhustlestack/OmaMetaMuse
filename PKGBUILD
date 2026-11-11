# Maintainer: J'Juan Wilson Jr. <hello@microhustlestack.com>
pkgname=muse-ai-omarchy-git
pkgver=0.1.0.r0.g0000000
pkgrel=1
pkgdesc="OmaMetaMuse by WSTUNLTD: Muse AI launcher plus a safe wrapper for Meta's official Muse Gadgets SDK on Omarchy"
arch=('any')
url="https://github.com/microhustlestack/omametamuse"
license=('MIT')
depends=('bash' 'curl')
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
  cd "$srcdir/omametamuse"
  printf "%s.r%s.g%s" "0.1.0" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "$srcdir/omametamuse"
  install -Dm755 bin/muse-ai "$pkgdir/usr/bin/muse-ai"
  install -Dm644 share/applications/Muse.desktop "$pkgdir/usr/share/applications/Muse.desktop"
  install -Dm644 share/applications/Muse.desktop "$pkgdir/usr/share/muse-ai-omarchy/Muse.desktop"
  install -Dm644 docs/TROUBLESHOOTING.md "$pkgdir/usr/share/doc/$pkgname/TROUBLESHOOTING.md"
  install -Dm644 docs/TESTED-HARDWARE.md "$pkgdir/usr/share/doc/$pkgname/TESTED-HARDWARE.md"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
