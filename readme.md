# Roy's NixOS Homelab Config

### Assumptions
<ul>
<li>You're connected to wired internet</li>
</ul>

### Setup Steps
1. Flash NixOS onto the server hardware
2. Create a sudo password for root
3. Run nixos anwhere command to install repo config: ```nix run github:nix-community/nixos-anywhere --extra-experimental-features "nix-command flakes" -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake '.#<nodeName>' root@<systemIP>```

### Random
<ul>
<li>Any time the quasiSecret Reop is updated, run ```nix flake lock --update-input quasiSecrets``` to ensure you're using the most recent pushed commit</li>
</ul>
