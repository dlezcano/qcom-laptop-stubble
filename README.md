# linux-stubble-postinst 1.0-1

Debian ARM64 package for the **user-supplied Stubble hook** and a separate global `initramfs-tools` setting.

## Installed files

- `/etc/kernel/postinst.d/stubble-efi` (0755) — the supplied POSIX shell script. Runs for kernel post-installation and is not restricted by a `*-stubble-test*` version pattern. It recognizes existing Stubble EFI images; otherwise, it selects a raw ARM64 `Image` from a matching kernel build tree when available, or the supplied installation source, and embeds available Qualcomm Glymur/Hamoa/X1E DTBs (excluding EL2) via `stubblify`. It validates the output and atomically installs the EFI image in `/boot/vmlinuz-$KVER` (or `STUBBLE_OUTPUT`, if set). It archives `/boot/vmlinux-$KVER` and `.old` after successful installation, unless `STUBBLE_OUTPUT` is specified. If the Qualcomm DTB directory or matching DTBs cannot be found, the script exits successfully **without** building the EFI image.
- `/usr/share/initramfs-tools/conf-hooks.d/stubble-initramfs-dep` (0644) — always sets **`MODULES=dep`** when `mkinitramfs` builds an initramfs, for **all kernels**, without a second generation. Leaves compression settings untouched.

The hook does not generate initramfs files. The `initramfs-tools` post-install hook generates them in its normal pass. The package does not regenerate existing initramfs files when installed.

## Build from the sources

```sh
./build-deb.sh
```

Expected output: `linux-stubble-postinst_1.0-1_arm64.deb`.

## Install / upgrade

```sh
sudo cp -a /etc/kernel/postinst.d/stubble-efi /root/stubble-efi.backup
sudo apt install ./linux-stubble-postinst_1.0-1_arm64.deb
```

As the hook is marked as a dpkg conffile, dpkg may ask whether to preserve locally modified content or install the new packaged version. Inspect the proposed change and select the desired version.

## Verify

```sh
dpkg-deb -I linux-stubble-postinst_1.0-1_arm64.deb
dpkg-deb -c linux-stubble-postinst_1.0-1_arm64.deb
run-parts --test /etc/kernel/postinst.d
cat /usr/share/initramfs-tools/conf-hooks.d/stubble-initramfs-dep
```

## Precautions

The user-supplied new hook is now eligible for **any kernel version**, not just test kernels. It explicitly skips when it cannot find a Qualcomm DTB directory, but if it finds a DTB directory and a non-raw/non-Stubble source image it fails; verify behavior with other packaged kernels. `MODULES=dep` makes initramfs images less portable to different hardware. Retain a bootable kernel and initramfs as a fallback before upgrading or regenerating images.
