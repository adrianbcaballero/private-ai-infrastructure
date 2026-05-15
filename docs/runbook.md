# Operational Runbook

## Quick Reference
| Command | Action |
|---|---|
| `wake` | Boot AI server (from desktop) |
| `server` | SSH into AI server |
| `down` | Shutdown AI server |
| `aegis` | SSH into aegis Pi |
| `wakeremote` | Boot AI server via aegis (remote) |

## Daily Operations

### Start AI Server
From desktop: `wake`
From remote via WireGuard: `wakeremote`

### Access Open WebUI
Local: `http://192.168.1.XXX:3000`
Remote: Connect WireGuard first, then same URL

### Access Pi-hole Dashboard
`http://192.168.1.XXX/admin`

## Remote Access Procedure
1. Open WireGuard app on phone or laptop
2. Toggle aegis-vpn tunnel on
3. Verify handshake: `sudo wg show` on aegis
4. Wake server if needed: `wakeremote`
5. Access Open WebUI or SSH normally

## Troubleshooting

### WireGuard not connecting
- Verify port forward: UDP 51820 → aegis IP
- Check WireGuard running: `sudo wg show`
- Check public IP hasn't changed: `curl -4 ifconfig.me`

### Pi-hole not blocking
- Check status: `pihole status`
- Verify DNS: `nslookup google.com` (should show aegis IP)
- Restart: `sudo systemctl restart pihole-FTL`

### SSH connection refused
- Check UFW rules: `sudo ufw status verbose`
- Verify SSH service: `sudo systemctl status sshd`
- Remember aegis uses port 2222