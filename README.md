# YARP Recovery for Samsung Galaxy Tab S9 Ultra Wi-Fi

This device tree targets the SM-X910 (`gts9uwifi`) and LineageOS 24. The r7 release includes LineageOS FBE decryption, MTP and ADB over FunctionFS, single-slot recovery configuration, the `/misc` bootloader-message entry, and a three-second Recovery USB startup delay.

The Samsung reboot-reason modules were tested by loading the exact modules on the tablet and confirming that a normal reboot reached LineageOS. r7 packages those modules in the ramdisk and has passed image and AVB verification. The r7 image itself has not been booted on the tablet.

r8 reads the battery from the kernel and releases the userdata mapping before formatting. Recovery suspends MTP during Format Data and restores it afterward if it was enabled.

## Build

Use a built LineageOS 24 tree for SM-X910 with kernel `0740b96ee364` (5.15.220), the CYG1-based vendor used by the ROM, and the matching `recovery.img`, `vendor_dlkm`, and prepared kernel build output. The preparation script stages the binaries and Samsung firmware files from that local build.

Initialize and sync the Android 16 YARP sources in a separate checkout.

```sh
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git \
  -b 814b553116ceedde197f70389cff9661d81d8337 --depth=1
repo sync -c --no-tags -j8

git clone https://github.com/zc4777-gts9u/android_device_samsung_gts9uwifi-yarp.git \
  device/samsung/gts9uwifi
git -C device/samsung/gts9uwifi checkout r8
DEVICE_TREE="$PWD/device/samsung/gts9uwifi"

# Select the source revisions used for r8 before applying its patches.
git -C bootable/recovery fetch --depth=1 https://github.com/TWRP-Test/android_bootable_recovery.git \
  a93a12ec107265ab9c3c7fe3e4f96c8740a01337
git -C bootable/recovery checkout --detach a93a12ec107265ab9c3c7fe3e4f96c8740a01337
git -C system/vold fetch --depth=1 https://github.com/TWRP-Test/android_system_vold.git \
  e7e26ed2ffd9ad0469a05515cfd91940a3366d19
git -C system/vold checkout --detach e7e26ed2ffd9ad0469a05515cfd91940a3366d19
git -C bootable/recovery apply "$DEVICE_TREE/patches/bootable-recovery.patch"
git -C system/vold apply "$DEVICE_TREE/patches/system-vold.patch"

"$DEVICE_TREE/prepare.sh" /path/to/built-lineage-24.0
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch twrp_gts9uwifi-bp2a-eng
mka recoveryimage -j12
```

The build output is `out/target/product/gts9uwifi/recovery.img`. The boot image format is header v2 with a dedicated Recovery partition. The release image is 109,576,192 bytes.

Sources are based on [YARP](https://github.com/TWRP-Test/android_bootable_recovery) and the [SM-X910 LineageOS tree](https://github.com/zc4777-gts9u/android_device_samsung_gts9uwifi). The kernel source for the prebuilt image and modules is [the SM8550 kernel at 0740b96ee364](https://github.com/zc4777-gts9u/android_kernel_samsung_sm8550/tree/0740b96ee364910c8900132954ac13aec46e380f), with the USB notifier change in `usb-notifier-boot-delay.patch`.
