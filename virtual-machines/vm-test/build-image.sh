#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   ./build-image.sh <vm-folder> <alias> [vmname]
#
# Example:
#   ./build-image.sh vm-test nixos/custom/jellybean
#
# Run from anywhere; all project operations use virtual-machines/.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 <vm-folder> <alias> [vmname]"
    exit 1
fi

VM_FOLDER="$1"
ALIAS="$2"
VMNAME="${3:-vm}"

VM_DIR="$SCRIPT_DIR/$VM_FOLDER"
SOPS_CONFIG="$SCRIPT_DIR/.sops.yaml"
AGE_DIR="/run/sops-virtual"
AGE_KEY="$AGE_DIR/virtual-key.txt"
SANDBOX_KEY="/run/sops-virtual-key.txt"

for cmd in age-keygen sops yq nix incus sudo; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing required command: $cmd" >&2
        exit 1
    }
done

[[ -d "$VM_DIR" ]] || {
    echo "VM directory not found: $VM_DIR" >&2
    exit 1
}

[[ -f "$VM_DIR/flake.nix" ]] || {
    echo "No flake.nix found in $VM_DIR" >&2
    exit 1
}

[[ -f "$SOPS_CONFIG" ]] || {
    echo "SOPS config not found: $SOPS_CONFIG" >&2
    exit 1
}

[[ -d "$VM_DIR/secrets" ]] || {
    echo "Secrets directory not found: $VM_DIR/secrets" >&2
    exit 1
}

# Refuse to overwrite a key that may belong to another running build.
if sudo test -e "$AGE_KEY"; then
    echo "Temporary key already exists: $AGE_KEY" >&2
    echo "Remove it or investigate the previous build before continuing." >&2
    exit 1
fi

SOPS_BACKUP="$(mktemp)"
AGE_TEMP="$(mktemp)"
cp -p "$SOPS_CONFIG" "$SOPS_BACKUP"

CLEANED_UP=0

cleanup() {
    local status=$?

    if [[ "$CLEANED_UP" -eq 1 ]]; then
        return
    fi
    CLEANED_UP=1

    # Restore the repository's original SOPS configuration.
    cp "$SOPS_BACKUP" "$SOPS_CONFIG"
    rm -f "$SOPS_BACKUP" "$AGE_TEMP"

    # Remove the temporary private key, even if the build failed.
    sudo rm -f "$AGE_KEY"
    sudo rmdir "$AGE_DIR" 2>/dev/null || true

    echo "Temporary age key removed."

    return "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Generating temporary age identity..."

age-keygen -o "$AGE_TEMP"
AGE_PUBLIC_KEY="$(age-keygen -y "$AGE_TEMP")"

# Make the key readable by Nix build users, but not ordinary users.
sudo install -d -o root -g nixbld -m 0750 "$AGE_DIR"
sudo install -o root -g nixbld -m 0440 \
    "$AGE_TEMP" "$AGE_KEY"

# Update age recipients in the SOPS creation rules temporarily.
# Requires mikefarah/yq v4 and simple comma-separated age fields.
export AGE_PUBLIC_KEY

if ! yq -e \
    '.creation_rules | any(.[]; has("age"))' \
    "$SOPS_CONFIG" >/dev/null; then
    echo "No creation_rules with an age field found in .sops.yaml" >&2
    exit 1
fi

yq -i '
    (.creation_rules[] | select(has("age")) | .age) |= (
        split(",")
        | map(trim)
        | map(select(. != ""))
        | . + [strenv(AGE_PUBLIC_KEY)]
        | unique
        | join(",")
    )
' "$SOPS_CONFIG"

echo "Updating SOPS recipients for secrets in $VM_FOLDER..."

shopt -s nullglob
SECRET_FILES=("$VM_DIR"/secrets/*)
shopt -u nullglob

if [[ ${#SECRET_FILES[@]} -eq 0 ]]; then
    echo "No secret files found in $VM_DIR/secrets" >&2
    exit 1
fi

for secret in "${SECRET_FILES[@]}"; do
    [[ -f "$secret" ]] || continue
    echo "Updating recipients: ${secret#"$SCRIPT_DIR"/}"
    sops updatekeys --yes "$secret"
done

echo "Building VM metadata..."

TARBALL_DIR="$(nix build \
    "./$VM_FOLDER#nixosConfigurations.${VMNAME}.config.system.build.metadata" \
    --print-out-paths)"

TARBALL="$(find "$TARBALL_DIR" -type f -name '*.tar.xz' -print -quit)"

if [[ -z "$TARBALL" ]]; then
    echo "Could not find a .tar.xz tarball in: $TARBALL_DIR" >&2
    exit 1
fi

echo "Metadata tarball: $TARBALL"

echo "Building QEMU disk image..."

QCOW2_DIR="$(nix build \
    "./$VM_FOLDER#nixosConfigurations.${VMNAME}.config.system.build.qemuImage" \
    --print-out-paths)"

QCOW2="$QCOW2_DIR/nixos.qcow2"

if [[ ! -f "$QCOW2" ]]; then
    echo "QEMU image not found: $QCOW2" >&2
    exit 1
fi

echo "QEMU image: $QCOW2"

echo "Importing image into Incus..."

incus image import \
    --alias "$ALIAS" \
    "$TARBALL" \
    "$QCOW2"

echo "Successfully imported image: $ALIAS"

