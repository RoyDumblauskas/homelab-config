# Server Steps

- [x] Set up declarative disk partitioning (ephemeral)
- [x] Implement SOPS for secret management
- [x] Lock down machine IP addresses, passed in through flake as param.
- [x] Set up port forwarding to server from router
- [x] Set up NGINX reverse proxy (or ingress controller for k8s?)
- [x] Buy Domain Name
- [x] Use ACME for Server Cert (Enable HTTPS) 
- [ ] Bootsrap private ssh key to sysAdmin user to allow local cloning of repo
- [ ] Add auto repo cloning to bootstrap
- [ ] Make build path location of automated repo cloning
- [ ] Define "services" directory to declare each service separately
- [ ] Add list of services to each hostname to define what they'll host (look into adding top layer reverse proxy if it's needed for multiple machines hosting separate services accross one domain name)
