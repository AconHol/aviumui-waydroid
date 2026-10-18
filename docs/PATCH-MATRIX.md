# AviumUI→Waydroid 移植：补丁试打最终表（base-patches-36 / A16）

总计 50 个补丁：OK=48  CONFLICT=2  UNTESTED=0


## bionic
- OK          0001-hybris-don-t-fail-because-of-fsetxattr.patch  [los]
- OK          0002-waydroid-add-vendor_extra-lib-folders-to-default-lib.patch  [los]
- OK          0003-linker-Allow-text-relocs-for-x86-only.patch  [los]
- OK          0004-Add-syscalls-ioperm-and-iopl.patch  [los]
- OK          0005-We-need-text-relocations.patch  [los]
- OK          0006-seccomp-Allow-SYS_kcmp-for-mesa.patch  [los]

## build/soong
- OK          0001-waydroid-do-not-fail-on-VNDK-ABI-mismatch.patch  [avium]
- CONFLICT    0002-Fix-building-on-A16.patch  [avium]
- OK          0003-Allow-compressed-dex-on-privileged-prebuilt-APKs.patch  [avium]
- OK          0004-Add-rust-tools-to-PATH-allowlist.patch  [avium]
- OK          0005-Allow-network-connection-in-sandbox.patch  [avium]

## device/google/atv
- OK          0001-Lift-maxUiWidth-restiction-on-ATV.patch  [los]

## device/lineage/sepolicy
- OK          0001-Remove-conflicting-selinux-labels.patch  [avium]

## external/libva-utils
- OK          0001-Android.bp-Include-libva_headers.patch  [material]
- OK          0002-Android.bp-Fix-license-file-location.patch  [material]

## external/llvm-project
- OK          0001-Fix-building-on-A16.patch  [material]

## external/selinux
- OK          0001-ignore-selinux.patch  [aosp]
- OK          0002-Suppress-SELinux-logs.patch  [aosp]

## external/wayland-protocols
- OK          0001-staging-Add-fractional-scale.patch  [aosp]

## hardware/libhardware
- OK          0001-waydroid-add-vendor_extra-lib-hw-to-HAL-search-path.patch  [los]
- OK          0002-libhardware-Don-t-check-for-ro.hardware.patch  [los]
- OK          0003-HACK-Avoid-crashes-on-SurfaceFlinger-when-using-soft.patch  [los]
- OK          0004-gralloc-Force-use-ashmem.patch  [los]
- OK          0005-gralloc-Support-more-pixel-formats.patch  [los]
- OK          0006-gralloc-Add-YUV-format-support.patch  [los]

## lineage-sdk
- CONFLICT    0001-trust-Suppress-SELinux-warning.patch  [avium]

## packages/apps/LineageCustomizer
- OK          0001-Add-fields-required-by-Google-TV-launcher.patch  [los]

## packages/apps/SetupWizard
- OK          0001-Skip-bluetooth-pairing-screen.patch  [avium]

## packages/modules/Bluetooth
- OK          0001-Replace-CLOCK_BOOTTIME_ALARM-with-CLOCK_BOOTTIME.patch  [los]

## packages/modules/Connectivity
- OK          0001-fix-booting.patch  [avium]
- OK          0002-ignore-nativeSynchronizeKernelRCU-error.patch  [avium]

## packages/modules/NetworkStack
- OK          0001-Disable-captive-portal-check-by-default.patch  [aosp]

## packages/modules/adb
- OK          0001-adb-Disable-selinux-when-root.patch  [los]
- OK          0002-Patching-ADBD-in-order-to-drop-privileges-unconditio.patch  [los]

## prebuilts/build-tools
- OK          0001-Add-prebuilt-mesa-tools-to-PATH.patch  [aosp]

## system/apex
- OK          0001-apexd-Configure-loop-device-on-detached-sysfs-mount.patch  [aosp]

## system/bpf
- OK          0001-Support-no-bpf-usecase.patch  [los]

## system/hwservicemanager
- OK          0001-halium-disable-SELinux-parts.patch  [aosp]

## system/libhwbinder
- OK          0001-Never-set-FLAT_BINDER_FLAG_TXN_SECURITY_CTX-flag.patch  [aosp]

## system/linkerconfig
- OK          0001-waydroid-add-vendor_extra-path-as-a-clone-of-vendor-.patch  [aosp]
- OK          0002-rootdir-Add-odm_extra-to-ld-paths.patch  [aosp]
- OK          0003-add-namespace-change-for-houdini.patch  [aosp]

## system/logging
- OK          0001-logd-Do-not-block-waiting-for-LogcatManagerService.patch  [los]

## system/memory/lmkd
- OK          0001-lmkd-Do-not-fail-when-both-vmpressure-and-psi-monito.patch  [aosp]

## system/netd
- OK          0001-ignore-iptables-error.patch  [avium]
- OK          0002-ignore-bpf-error.patch  [avium]
- OK          0003-ignote-getTetherStats-error.patch  [avium]

## system/security
- OK          0001-keystore2-Ignore-selinux-checks.patch  [avium-16.2]

## vendor/intel/gmmlib
- OK          0001-Android.bp-Update-source-file-list.patch  [material]
- OK          0002-Allow-building-on-32-bit-x86.patch  [material]
