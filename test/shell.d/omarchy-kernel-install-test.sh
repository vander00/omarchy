#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

leaf="$ROOT/install/hardware/kernel.sh"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin"
export PATH="$scratch/bin:$PATH" CALL_LOG="$scratch/calls"

cat > "$scratch/bin/uname" <<'SH'
#!/bin/bash
[[ $* == "-m" ]] || exit 99
printf '%s\n' "${TEST_ARCH:-x86_64}"
SH

cat > "$scratch/bin/omarchy-pkg-present" <<'SH'
#!/bin/bash
[[ $* == "linux-t2" ]] || exit 99
[[ ${T2_INSTALLED:-0} == "1" ]]
SH

cat > "$scratch/bin/lspci" <<'SH'
#!/bin/bash
[[ $* == "-nn" ]] || exit 99
[[ ${PCI_FAIL:-0} == "0" ]] || exit 1
printf '%s\n' "${PCI_DEVICES:-00:02.0 VGA compatible controller: Intel [8086:1234]}"
SH

cat > "$scratch/bin/omarchy-pkg-add" <<'SH'
#!/bin/bash
printf 'add %s\n' "$*" >> "$CALL_LOG"
[[ ${INSTALL_FAIL:-0} == "0" ]]
SH
chmod +x "$scratch/bin/"*

run_leaf() {
  : > "$CALL_LOG"
  bash -euo pipefail "$leaf" > "$scratch/output" 2>&1
}

run_leaf
grep -Fxq 'add linux-omarchy linux-omarchy-headers' "$CALL_LOG" || fail "ordinary systems install the generic kernel and headers"
pass "ordinary x86_64 installs receive the Omarchy kernel without a Panther Lake hardware gate"

T2_INSTALLED=1 run_leaf
[[ ! -s $CALL_LOG ]] || fail "an installed T2 kernel excludes the system"
pass "hardware setup skips systems with linux-t2 installed"

for device in 1801 1802; do
  PCI_DEVICES="04:00.0 Mass storage controller: Apple Inc. T2 [106b:$device]" run_leaf
  [[ ! -s $CALL_LOG ]] || fail "fresh T2 hardware must not install the generic kernel"
done
pass "fresh T2 hardware is excluded before its specialized kernel has been installed"

TEST_ARCH=aarch64 run_leaf
[[ ! -s $CALL_LOG ]] || fail "ARM hardware cannot install an x86_64 kernel"
pass "ARM hardware is excluded"

if PCI_FAIL=1 run_leaf; then
  fail "failed T2 hardware detection must stop kernel setup"
fi
[[ ! -s $CALL_LOG ]] || fail "unidentified hardware must not install the generic kernel"
pass "failed PCI detection prevents installing the generic kernel on unidentified hardware"

if INSTALL_FAIL=1 run_leaf; then
  fail "package installation failure must fail kernel setup"
fi
pass "kernel package installation failures stop hardware setup"

kernel_line=$(grep -n 'hardware/kernel.sh' "$ROOT/install/hardware/all.sh" | cut -d: -f1)
for script in nvidia.sh intel/ipu7-camera.sh fix-elgato-camlink-4k.sh; do
  driver_line=$(grep -n "hardware/$script" "$ROOT/install/hardware/all.sh" | cut -d: -f1)
  (( kernel_line < driver_line )) || fail "the generic kernel is installed before $script pulls in DKMS drivers"
done
pass "kernel setup precedes NVIDIA, IPU7, and Cam Link DKMS setup"

for package in linux-omarchy linux-omarchy-headers; do
  grep -Fxq "$package" "$ROOT/install/omarchy-other.packages" || fail "the ISO includes $package"
done
! grep -q 'linux-omarchy-ptl-novrr-mm' "$ROOT/install/omarchy-other.packages" || fail "the ISO must not pull in the retired PTL variant"
pass "the ISO package list includes the generic kernel and headers"
