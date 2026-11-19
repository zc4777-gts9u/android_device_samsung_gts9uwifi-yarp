#!/usr/bin/env python3
"""Stage the device's installed crypto HALs and their vendor ELF dependencies."""
import re
import shutil
import subprocess
import sys
from pathlib import Path

product = Path(sys.argv[1])
vendor = product / "vendor"
root = Path(__file__).resolve().parent / "recovery/root/vendor"
shutil.copytree(vendor / "etc/secnvm", root / "etc/secnvm", dirs_exist_ok=True)

hal_paths = [
    "bin/qseecomd",
    "bin/hermesd",
    "bin/spdaemon",
    "bin/sec_nvm",
    "bin/hw/android.hardware.security.keymint-service-qti",
    "bin/hw/android.hardware.gatekeeper@1.0-service",
    "lib64/hw/android.hardware.gatekeeper@1.0-impl.so",
    "lib64/hw/gatekeeper.mdfpp.so",
]

# Keep Bionic, Binder and other cross-partition system libraries from YARP.
platform_libs = {
    "libandroidicu.so", "libbase.so", "libbinder_ndk.so",
    "libc.so", "libcgrouprc.so", "libcutils.so", "libdl.so", "libhidlbase.so",
    "libjsoncpp.so", "liblog.so", "libm.so", "libprocessgroup.so",
    "libutils.so", "libvndksupport.so", "libz.so",
}

queue = [vendor / path for path in hal_paths]
seen = set()
platform_needed = set()
missing = set()
while queue:
    source = queue.pop()
    relative = source.relative_to(vendor)
    if relative in seen:
        continue
    seen.add(relative)
    if not source.is_file():
        missing.add(str(relative))
        continue
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target, follow_symlinks=True)
    dynamic = subprocess.check_output(["readelf", "-d", source], text=True)
    for soname in re.findall(r"\(NEEDED\).*?\[([^]]+)\]", dynamic):
        if soname in platform_libs:
            platform_needed.add(soname)
            continue
        matches = [vendor / directory / soname for directory in ("lib64", "lib64/hw")]
        implementation = next((path for path in matches if path.is_file()), None)
        if implementation is None:
            platform_needed.add(soname)
        else:
            queue.append(implementation)

for soname in sorted(platform_needed):
    print("YARP system dependency:", soname)
if missing:
    sys.exit("Missing Samsung crypto files: " + ", ".join(sorted(missing)))
print("Staged vendor ELF objects:", len(seen))
