#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   ./build-image.sh -f <vm-folder> -a <alias> -n [vmname]
#
# Example:
#   ./build-image.sh vm-test nixos/custom/jellybean

VM_FOLDER=""
ALIAS=""
VM_NAME="vm"
SOPS_CONFIG=".sops.yaml"
AGE_DIR="/run/sops-virtual"
AGE_KEY="$AGE_DIR/virtual-key.txt"

while getopts ":f:a:n:" flag; do
  case $flag in
    f) VM_FOLDER="./$OPTARG" ;;
    a) ALIAS="$OPTARG" ;;
    n) VM_NAME="$OPTARG" ;;
    \?) echo "Error: Invalid option -$OPTARG" >&2; exit 1 ;;
    :)  echo "Error: Option -$OPTARG requires an argument" >&2; exit 1 ;;
  esac
done

# Validate required commands
for cmd in age-keygen sops yq nix incus sudo; do
  command -v "$cmd" >/dev/null 2>&1 || {
	  echo "Missing required command: $cmd" >&2
	  exit 1
	}
done

# Validate required arguments
if [[ -z "$VM_FOLDER" ]]; then
  echo "Error: -f <vm-folder> is required" >&2
  exit 1
fi

if [[ -z "$ALIAS" ]]; then
  echo "Error: -a <alias> is required" >&2
  exit 1
fi

# Validate argument requirements
if [[ ! -d "$VM_FOLDER" ]]; then
  echo "Error: directory $VM_FOLDER must exist" >&2
  exit 1
fi

if [[ ! -f "$VM_FOLDER/flake.nix" ]]; then
  echo "Error: no flake file found in $VM_FOLDER" >&2
  exit 1
fi

if [[ ! -f "$SOPS_CONFIG" ]]; then
  echo "Error: no sops config found" >&2
  exit 1
fi

if sudo test -e "$AGE_KEY"; then
  echo "Temp key already exists, removing $AGE_KEY" >&2
  sudo truncate -s 0 "$AGE_KEY"
else
  echo "Creating key file $AGE_KEY" >&2
  sudo touch "$AGE_KEY"
fi

SOPS_BACKUP="$(mktemp)"
AGE_TEMP="$(mktemp)"
rm -f "$AGE_TEMP"

cp -p "$SOPS_CONFIG" "$SOPS_BACKUP"

cleanup() {
  cp "$SOPS_BACKUP" "$SOPS_CONFIG"

  if [[ -d "$VM_FOLDER/secrets" ]]; then
    shopt -s nullglob
    local secret_files=("$VM_FOLDER"/secrets/*)
    shopt -u nullglob

    for secret in "${secret_files[@]}"; do
      [[ -f "$secret" ]] || continue
      echo "Restoring SOPS recipients: ${secret#"$PWD"/}"
      if ! sops updatekeys --yes "$secret"; then
          echo "WARNING: Failed to restore recipients in $secret" >&2
          status=1
      fi
    done
  fi

  rm -f "$SOPS_BACKUP" "$AGE_TEMP"

  sudo truncate -s 0 "$AGE_KEY"
  echo "Age key erased"

  return 0
}

trap cleanup EXIT

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

# Confirm at least one age key group exists.
if ! yq -e '
  [.creation_rules[].key_groups[] | select(.age != null)] | length > 0
' "$SOPS_CONFIG" >/dev/null; then
    echo "No creation_rules with key_groups.age found in .sops.yaml" >&2
    exit 1
fi

# Add the temporary public key to each age recipient list.
yq -y -i '
  (.creation_rules[].key_groups[] | select(.age != null).age) |=
    (. + [env.AGE_PUBLIC_KEY] | unique)
' "$SOPS_CONFIG"

echo "Updating SOPS recipients for secrets in $VM_FOLDER..."

shopt -s nullglob
SECRET_FILES=("$VM_FOLDER"/secrets/*)
shopt -u nullglob

if [[ ${#SECRET_FILES[@]} -eq 0 ]]; then
    echo "No secret files found in $VM_FOLDER/secrets" >&2
    exit 1
fi

for secret in "${SECRET_FILES[@]}"; do
    [[ -f "$secret" ]] || continue
    echo "Updating recipients: ${secret#"$PWD"/}"
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


