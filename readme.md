# Roy's NixOS Homelab Config

### Assumptions
- You're connected to wired internet (eth)
- You're me; To directly run/use this config, you have to be me (i.e. have my ssh private keys to pull in quasiSecrets and my age keys to decrypt with sops-nix)

### Setup Steps
1. Flash NixOS onto the server hardware
2. Create a sudo password for root ```sudo passwd```
3. Get IP address with ```ip addr```
4. From the nixos directory, run the bash script ```bootstrap.sh``` using IP address from step 3 (```./bootstrap.sh -h``` for options)

### Random
- Any time the quasiSecret repository is updated, run ```nix flake lock --update-input quasiSecrets``` to ensure you're using the most recent pushed commit
- If you aren't me, replace my quasiSecrets repo with your own, update the .sops.yaml file with your own age key to update the ```secrets/*``` files, place your own hashed user password into the ```users.users.<userName>.hashedPassord```, and your own public key into ```users.users.<userName>.openssh.authorizedKeys.keys```
