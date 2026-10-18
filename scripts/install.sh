#!/bin/sh
# Install the AviumUI 16.2 Waydroid images.
#
#   ./scripts/install.sh ./images
#
# The directory must contain system.img and vendor.img (from the release assets).
# Verifies SHA256SUMS, copies to /etc/waydroid-extra/images, runs waydroid init.
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST=/etc/waydroid-extra/images
IMG_DIR=${1:-}

die() { echo "install: $*" >&2; exit 1; }

[ -n "$IMG_DIR" ] || die "usage: $0 <dir with system.img and vendor.img>"
[ -d "$IMG_DIR" ] || die "no such directory: $IMG_DIR"
for f in system.img vendor.img; do
    [ -f "$IMG_DIR/$f" ] || die "$IMG_DIR/$f missing"
done

command -v waydroid >/dev/null || die "waydroid not installed"
id -u >/dev/null

echo "== verifying checksums"
( cd "$IMG_DIR" && grep -E ' (system|vendor)\.img$' "$REPO/SHA256SUMS" | sha256sum -c - ) || die "checksum mismatch"

echo "== copying to $DEST"
sudo mkdir -p "$DEST"
sudo install -m 0644 "$IMG_DIR/system.img" "$DEST/system.img"
sudo install -m 0644 "$IMG_DIR/vendor.img" "$DEST/vendor.img"

echo "== waydroid init -i $DEST -f"
sudo /usr/bin/python3 /usr/sbin/waydroid init -i "$DEST" -f

echo "== restarting waydroid-container"
sudo systemctl restart waydroid-container

echo "== waiting for boot"
i=0
while [ $i -lt 60 ]; do
    if sudo lxc-attach -P /var/lib/waydroid/lxc -n waydroid --clear-env -- \
        /system/bin/sh -c 'test "$(getprop sys.boot_completed)" = 1' 2>/dev/null; then
        echo "boot completed after $((i * 3))s"
        echo "run: waydroid show-full-ui"
        exit 0
    fi
    sleep 3
    i=$((i + 1))
done

die "boot did not complete in 180s — see: sudo journalctl -u waydroid-container -n 100"
