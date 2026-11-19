#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/built-lineage-24.0" >&2
    exit 2
fi

device=$(cd "$(dirname "$0")" && pwd)
lineage=$(realpath "$1")
product="$lineage/out/target/product/gts9uwifi"
kernel_build="$product/obj/KERNEL_OBJ"
kernel_source="$lineage/kernel/samsung/sm8550"
modules="$device/recovery/root/lib/modules"
vendor_modules="$product/vendor_dlkm/lib/modules"
toolchain="$lineage/prebuilts/clang/host/linux-x86/clang-r596125/bin"
boot_tools="$lineage/prebuilts/kernel-build-tools/linux-x86/bin"
build_tools="$lineage/prebuilts/build-tools/linux-x86/bin"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

test -s "$product/recovery.img"
test -s "$kernel_build/Module.symvers"
test -x "$boot_tools/pahole"
test -x "$toolchain/clang"
mkdir -p "$work/image" "$work/ramdisk" "$work/module" "$device/prebuilt"
python3 "$lineage/system/tools/mkbootimg/unpack_bootimg.py" \
    --boot_img "$product/recovery.img" --out "$work/image"
for component in kernel dtb recovery_dtbo; do
    install -m 0644 "$work/image/$component" "$device/prebuilt/$component"
done
(cd "$work/ramdisk"; lz4 -dc ../image/ramdisk | cpio -idm --quiet --no-absolute-filenames 'lib/modules/*.ko')

# Reuse the module set from the tested Recovery build.
while IFS=: read -r path _; do
    name=${path##*/}
    case "$name" in
        sec_qc_rbcmd.ko|sec_qc_qcom_reboot_reason.ko|smcinvoke_dlkm.ko)
            source="$vendor_modules/$name"
            ;;
        *)
            source="$work/ramdisk/lib/modules/$name"
            ;;
    esac
    install -m 0644 "$source" "$modules/$name"
done <"$modules/modules.dep"

cp "$kernel_source/drivers/usb/notify/usb_notifier_qcom.c" "$work/module/"
patch "$work/module/usb_notifier_qcom.c" <"$device/usb-notifier-boot-delay.patch"
printf '%s\n' 'obj-m += usb_notifier_qcom.o' >"$work/module/Makefile"
PATH="$toolchain:$build_tools:$boot_tools:$PATH" KCONFIG_NOSILENTUPDATE=1 \
    make -C "$kernel_build" M="$work/module" ARCH=arm64 LLVM=1 LLVM_IAS=1 -j4 modules
new_module="$work/module/usb_notifier_qcom.ko"
test "$(modinfo -F vermagic "$new_module")" = "$(modinfo -F vermagic "$modules/usb_notifier_qcom.ko")"
"$toolchain/llvm-strip" --strip-debug -o "$modules/usb_notifier_qcom.ko" "$new_module"

python3 "$device/stage-crypto.py" "$product"
