#!/usr/bin/env bash

# User variables
target_hostname=""
target_destination=""
target_user=${BOOTSTRAP_USER-root} # Set BOOTSTRAP_ defaults in your shell.nix
ssh_port=${BOOTSTRAP_SSH_PORT-22}

# ---HELPER FUNCTIONS START---
SOPS_FILE=".sops.yaml"

# Updates the .sops.yaml file with a new host age key.
function sops_update_age_key() {
	keyname="$1"
	key="$2"

  if [[ -n $(yq ".keys.hosts[] | select(anchor == \"$keyname\")" "${SOPS_FILE}") ]]; then
		echo "Updating existing ${keyname} key"
		yq -i "(.keys.hosts[] | select(anchor == \"$keyname\")) = \"$key\"" "$SOPS_FILE"
	else
		echo "Adding new ${keyname} key"
		yq -i ".keys.hosts += [\"$key\"] | .keys.hosts[-1] anchor = \"$keyname\"" "$SOPS_FILE"
	fi
}

# Update key groups to have new host's sops key
function sops_add_host_to_key_groups() {
	h="\"$1\""                    # quoted hostname for yaml
  
  if [[  -z $(yq "select(.creation_rules[].key_groups[].age[] == $h)" "$SOPS_FILE") ]]; then
    echo "Adding key to key group"
    yq -i ".creation_rules[].key_groups[].age += [ $h ]" "$SOPS_FILE"
    yq -i ".creation_rules[].key_groups[].age[-1] alias = $h" "$SOPS_FILE"
  else
    echo "Reference already exists in key group"
  fi
}

# Use generated ssh key generate age key, and update sops
# args: target_key
function sops_generate_host_age_key() {
	echo "Generating an age key based on the new ssh_host_ed25519_key"

	# Get the SSH key
	target_key="$1"
	host_age_key=$(echo "$target_key" | ssh-to-age)
  
	if grep -qv '^age1' <<<"$host_age_key"; then
		echo "The result from generated age key does not match the expected format."
		echo "Result: $host_age_key"
		echo "Expected format: age10000000000000000000000000000000000000000000000000000000000"
		exit 1
	fi

	echo "Updating nix-secrets/.sops.yaml"
	sops_update_age_key "$target_hostname" "$host_age_key"
  sops_add_host_to_key_groups "$target_hostname"
  sops updatekeys secrets/*
}

function help_and_exit() {
	echo
	echo "Remotely installs NixOS on a target machine using this nix-config."
	echo
	echo "USAGE: $0 -n <target_hostname> -d <target_destination> [OPTIONS]"
	echo
	echo "ARGS:"
	echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on."
	echo "  -d <target_destination>                 specify ip or domain to the target host."
	echo
	echo "OPTIONS:"
	echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
	echo "                                          Default=root."
	echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=${ssh_port}."
	echo "  --debug                                 Enable debug mode."
	echo "  -h | --help                             Print this help."
	exit 0
}

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

await_boot() {
  local host=$1
  local user=${2:-root}  # default to root if not provided
  local timeout=${3:-2}  # default SSH connect timeout (seconds)
  
  if [[ -z "$host" ]]; then
    echo "Usage: await_boot <host> [user] [timeout]"
    return 1
  fi

  echo "Waiting for SSH to become available at ${user}@${host}..."
  
  until ssh -o ConnectTimeout=$timeout -o StrictHostKeyChecking=no -o BatchMode=yes "${user}@${host}" 'exit' 2>/dev/null; do
    sleep 2
  done
  
  echo "SSH is now available at ${user}@${host}."
}

# ---HELPER FUNCTIONS END---

# Create a temporary directory
temp=$(mktemp -d)

# Handle command-line arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-n)
		shift
		target_hostname=$1
		;;
	-d)
		shift
		target_destination=$1
		;;
	-u)
		shift
		target_user=$1
		;;
	--port)
		shift
		ssh_port=$1
		;;
	--debug)
		set -x
		;;
	-h | --help) help_and_exit ;;
	*)
		echo "ERROR: Invalid option detected."
		help_and_exit
		;;
	esac
	shift
done

if [ -z "$target_hostname" ] || [ -z "$target_destination" ]; then
	echo "ERROR: -n, -d, and -k are all required"
	echo
	help_and_exit
fi

# delete known hosts
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/persist/etc/ssh"

# Generate private key and copy it to the temporary directory
ssh-keygen -t ed25519 -f "$temp/persist/etc/ssh/ssh_host_ed25519_key" -C "$target_user"@"$target_hostname" -N ""

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/persist/etc/ssh/ssh_host_ed25519_key"

# update sops with new host ssh key | age key
target_key=$(cut -f1- -d" " "$temp/persist/etc/ssh/ssh_host_ed25519_key.pub")
sops_generate_host_age_key "$target_key"

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere --extra-experimental-features "nix-command flakes" -- --ssh-port "$ssh_port" --post-kexec-ssh-port "$ssh_port" --extra-files "$temp" --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --disko-mode disko --build-on local --flake .#"$target_hostname" --target-host "$target_user"@"$target_destination"

echo "\nConfig Successfully Deployed\n"

