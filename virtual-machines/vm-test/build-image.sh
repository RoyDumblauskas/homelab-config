#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./build-image.sh <alias> [vmname]
#
# Examples:
#   ./build-image.sh nixos/custom/vm
#   ./build-image.sh nixos/custom/my-vm my-vm

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <alias> [vmname]"
    echo
    echo "  alias   Required Incus image alias"
    echo "  vmname  NixOS configuration name (default: vm)"
    exit 1
fi

ALIAS="$1"
VMNAME="${2:-vm}"

# Build the NixOS LXC metadata tarball
TARBALL_DIR="$(nix build \
    ".#nixosConfigurations.${VMNAME}.config.system.build.metadata" \
    --print-out-paths)"

# Find the tarball
TARBALL="$(find "$TARBALL_DIR" -type f -name '*.tar.xz' -print -quit)"

if [[ -z "$TARBALL" ]]; then
    echo "Could not find a .tar.xz tarball in: $TARBALL_DIR"
    exit 1
fi

echo "Metadata tarball: $TARBALL"

# Build the QEMU disk image
QCOW2_DIR="$(nix build \
    ".#nixosConfigurations.${VMNAME}.config.system.build.qemuImage" \
    --print-out-paths)"

QCOW2="$QCOW2_DIR/nixos.qcow2"

if [[ ! -f "$QCOW2" ]]; then
    echo "QEMU image not found: $QCOW2"
    exit 1
fi

echo "Found QEMU image: $QCOW2"

echo
echo "Importing image into Incus..."

incus image import \
    --alias "$ALIAS" \
    "$TARBALL" \
    "$QCOW2"

echo
echo "Successfully imported image: $ALIAS"

