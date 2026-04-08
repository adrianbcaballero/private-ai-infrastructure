# Fail2ban Configuration

## Installed On
- Aegis (Pi)

## Configuration (/etc/fail2ban/jail.local)
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

## Check Status
sudo fail2ban-client status sshd

## View Banned IPs
sudo fail2ban-client status sshd | grep "Banned IP"