#!/bin/sh
set -eu

SELF=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PACKAGE=linux-stubble-postinst
VERSION=${1:-1.0-1}
ARCH=arm64

for src in stubble-efi stubble-initramfs-dep; do
    [ -f "$SELF/$src" ] || {
        echo "Missing source: $SELF/$src" >&2
        exit 1
    }
    sh -n "$SELF/$src"
done

STAGING=$(mktemp -d)
chmod 0755 "$STAGING"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/DEBIAN" \
    "$STAGING/etc/kernel/postinst.d" \
    "$STAGING/usr/share/initramfs-tools/conf-hooks.d"

install -m 0755 "$SELF/stubble-efi" \
    "$STAGING/etc/kernel/postinst.d/stubble-efi"
install -m 0644 "$SELF/stubble-initramfs-dep" \
    "$STAGING/usr/share/initramfs-tools/conf-hooks.d/stubble-initramfs-dep"

cat > "$STAGING/DEBIAN/control" <<CONTROL
Package: $PACKAGE
Version: $VERSION
Section: kernel
Priority: optional
Architecture: $ARCH
Maintainer: Daniel Lezcano <daniel.lezcano@oss.qualcomm.com>
Depends: stubble, binutils, initramfs-tools, file
Description: Qualcomm ARM64 Stubble postinstall and dependency-based initramfs
 Wraps raw ARM64 kernel Image files with Stubble EFI and Qualcomm DTBs.
 Sets MODULES=dep for all kernels during regular initramfs generation.
CONTROL

printf '%s\n' /etc/kernel/postinst.d/stubble-efi \
    > "$STAGING/DEBIAN/conffiles"

OUT="$SELF/${PACKAGE}_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group --build "$STAGING" "$OUT"
printf 'Built: %s\n' "$OUT"
