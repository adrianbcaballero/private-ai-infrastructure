# UFW Firewall Rules

## Rules on Aegis

| Rule | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| ALLOW | 2222 | TCP | 192.168.1.0/24 | SSH local only |
| ALLOW | 51820 | UDP | Anywhere | WireGuard VPN |
| ALLOW | 53 | UDP/TCP | 192.168.1.0/24 | Pi-hole DNS |
| ALLOW | 80 | TCP | 192.168.1.0/24 | Pi-hole admin |
| DENY | all | all | Anywhere | Default deny |

## To Apply
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 2222
sudo ufw allow 51820/udp
sudo ufw allow from 192.168.1.0/24 to any port 53
sudo ufw allow from 192.168.1.0/24 to any port 80
sudo ufw enable