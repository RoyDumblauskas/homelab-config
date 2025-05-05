# Roy's NixOS Homelab Config

### Assumptions
<ul>
<li>You're connected to wired internet</li>
</ul>

### Setup Steps
1. Flash NixOS onto the server hardware
2. Create a sudo password for root ```sudo passwd```
3. Run the bash script ```homelab-config/nixos/script.sh```

### Random
- Any time the quasiSecret repository is updated, run ```nix flake lock --update-input quasiSecrets``` to ensure you're using the most recent pushed commit


