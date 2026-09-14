# Install the default kernel before hardware setup pulls in DKMS modules.
# On a fresh T2 install linux-t2 is not installed yet, so also check the chip.
if [[ $(uname -m) == "x86_64" ]] && ! omarchy-pkg-present linux-t2; then
  pci_devices=$(lspci -nn)
  if ! grep "106b:180[12]" <<< "$pci_devices" >/dev/null; then
    echo "Installing the Omarchy kernel..."
    omarchy-pkg-add linux-omarchy linux-omarchy-headers
  fi
fi
