# SSH Hardening

## Changes Made to /etc/ssh/sshd_config
Port changed to 2222  
PermitRootLogin no  
PasswordAuthentication no  
PubkeyAuthentication yes  

## Important
Check /etc/ssh/sshd_config.d/ for override files.  
cloud-init may set PasswordAuthentication yes in  
50-cloud-init.conf — change this to no.  

## Key Management
Each device gets its own key pair.  
Keys generated with: ssh-keygen -t ed25519