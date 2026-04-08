# Network Reference

## Device IPs
| Device | IP | Notes |
|---|---|---|
| Router | 192.168.1.1 | Admin panel |
| Desktop | 192.168.1.XXX | Admin workstation |
| AI Server (aeglero-ai) | 192.168.1.XXX | Ubuntu, SSH port 22 |
| Aegis (Pi) | 192.168.1.XXX | SSH port 2222 |

## Ports
| Port | Protocol | Service | Exposed |
|---|---|---|---|
| 51820 | UDP | WireGuard VPN | Public |
| 2222 | TCP | SSH (aegis) | Internal only |
| 22 | TCP | SSH (aeglero-ai) | Internal only |
| 53 | UDP/TCP | Pi-hole DNS | Internal only |
| 80 | TCP | Pi-hole admin | Internal only |
| 3000 | TCP | Open WebUI | Internal only |