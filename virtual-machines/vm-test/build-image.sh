#!/usr/bin/env bash
set -euo pipefail

# Configuration
ALIAS="nixos/custom/vm"
VM_NAME="vmname"

# Build the NixOS LXC metadata tarball
TARBALL_DIR="$(nix build \
  ".#nixosConfigurations.${VM_NAME}.config.system.build.metadata" \
  --print-out-paths)"

# Find the tarball using find -type f
TARBALL="$(find "$TARBALL_DIR" -type f -name '*.tar.xz' -print -quit)"

if [[ -z "$TARBALL" ]]; then
    echo "Error: Could not find a .tar.xz tarball in:"
    echo "  $TARBALL_DIR"
    exit 1
fi

echo "Found metadata tarball:"
echo "  $TARBALL"

# Build the QEMU disk image
QCOW2="$(nix build \
  ".#nixosConfigurations.${VM_NAME}.config.system.build.qemuImage" \
  --print-out-paths)/nixos.qcow2"

if [[ ! -f "$QCOW2" ]]; then
    echo "Error: QEMU image not found:"
    echo "  $QCOW2"
    exit 1
fi

echo "Importing NixOS image into Incus..."
echo "  Alias:   $ALIAS"
echo "  Tarball: $TARBALL"
echo "  Image:   $QCOW2"

incus image import \
    --alias "$ALIAS" \
    "$TARBALL" \
    "$QCOW2"

echo "Successfully imported image as: $ALIAS"

