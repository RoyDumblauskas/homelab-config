#!/usr/bin/env bash

# User variables
target_hostname=""
target_destination=""
target_user=${BOOTSTRAP_USER-root} # Set BOOTSTRAP_ defaults in your shell.nix
ssh_port=${BOOTSTRAP_SSH_PORT-22}
ssh_key=${BOOTSTRAP_SSH_KEY-}

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

function help_and_exit() {
	echo
	echo "Remotely installs NixOS on a target machine using this nix-config."
	echo
	echo "USAGE: $0 -n <target_hostname> -d <target_destination> -k <ssh_key> [OPTIONS]"
	echo
	echo "ARGS:"
	echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on."
	echo "  -d <target_destination>                 specify ip or domain to the target host."
	echo "  -k <ssh_key>                            specify the full path to the ssh_key you'll use for remote access to the"
	echo "                                          target during install process."
	echo "                                          Example: -k /home/${target_user}/.ssh/my_ssh_key"
	echo
	echo "OPTIONS:"
	echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
	echo "                                          Default=root."
	echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=${ssh_port}."
	echo "  --debug                                 Enable debug mode."
	echo "  -h | --help                             Print this help."
	exit 0
}

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
	-k)
		shift
		ssh_key=$1
		;;
	--port)
		shift
		ssh_port=$1
		;;
	--temp-override)
		shift
		temp=$1
		;;
	--debug)
		set -x
		;;
	-h | --help) help_and_exit ;;
	*)
		red "ERROR: Invalid option detected."
		help_and_exit
		;;
	esac
	shift
done

if [ -z "$target_hostname" ] || [ -z "$target_destination" ] || [ -z "$ssh_key" ]; then
	red "ERROR: -n, -d, and -k are all required"
	echo
	help_and_exit
fi

# Create the directory where sshd expects to find the host keys
install -d -m755 "$tempSSH/persist/etc/ssh"

# Generate private key and copy it to the temporary directory
ssh-keygen -t ed25519 -f "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key" -C "$target_user"@"$target_hostname" -N ""

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/persist/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere --extra-experimental-features "nix-command flakes" -- --ssh-port "$ssh_port" --post-kexec-ssh-port "$ssh_port" --extra-files "$temp" --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --disko-mode disko --build-on local --flake .#"$target_hostname" --target-host "$target_user"@"$target_destination"

