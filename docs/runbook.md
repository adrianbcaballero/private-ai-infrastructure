# Operational Runbook

## Quick Reference (Admin Workstation)
| Command | Action |
|---|---|
| `wake` | Wake AI server via aegis (works locally and remotely) |
| `server` | SSH into AI server (10.10.10.10) |
| `down` | Shutdown AI server |
| `aegis` | SSH into aegis Pi |

## Daily Operations

### Start AI Server
- **From admin workstation (local):** `wake`
- **From remote (anywhere):** connect WireGuard first, then `wake`

Both paths route through aegis — admin's wired connection
is on VLAN 20, which cannot directly broadcast WoL to VLAN 10.
The `wake` alias SSHes into the Pi and runs `~/wake-server.sh`,
which broadcasts the magic packet on the VLAN 10 segment.

### Access Open WebUI
- **Local (wired admin):** `http://10.10.10.10:3000`
- **Remote (VPN):** connect WireGuard first, then same URL
- **From WiFi:** not accessible by design (no route to VLAN 10)

### Access Pi-hole Dashboard
- **From admin workstation:** `http://<aegis-egress-ip>/admin`
- **From WiFi:** not accessible (admin-VLAN-only)

## Remote Access Procedure
1. Open WireGuard client on phone or laptop
2. Connect to aegis tunnel
3. Verify handshake on Pi: `sudo wg show`
4. Wake AI server if needed: `ssh -p 2222 <user>@<aegis-vpn-ip> '~/wake-server.sh'`
5. Access Open WebUI at `http://10.10.10.10:3000`
6. Or SSH directly: `ssh <user>@10.10.10.10`

## Troubleshooting

### WireGuard not connecting
- Verify Spectrum port forward: UDP 51820 → aegis IP
- Check service running on Pi: `sudo wg show`
- Check public IP hasn't changed: `curl -4 ifconfig.me`

### AI Server unreachable from admin
- Verify wired adapter has VLAN 20 IP: `Get-NetIPAddress -InterfaceAlias "Ethernet"`
- Confirm Ethernet default route has low metric (not losing to WiFi):
  `Get-NetRoute -DestinationPrefix "0.0.0.0/0"`
- Verify Pi forwarding: `cat /proc/sys/net/ipv4/ip_forward` (should be `1`)
- Check Pi forward chain counters: `sudo iptables -L ufw-user-forward -n -v`

### Pi-hole not blocking
- Check status: `pihole status`
- Verify clients are using Pi as DNS: `nslookup google.com`
- Restart: `sudo systemctl restart pihole-FTL`

### SSH connection refused
- Confirm source IP is in an allowed subnet (10.20.20.0/24 or via wg0)
- Check UFW: `sudo ufw status verbose`
- Verify SSH service: `sudo systemctl status ssh`
- Remember aegis uses port 2222
- Check Fail2ban for accidental ban: `sudo fail2ban-client status sshd`

### Switch UI unreachable
- Switch management lives on VLAN 30 (192.168.1.0/24)
- Reachable from WiFi directly (same subnet)
- Reachable from admin VLAN via Pi NAT
- Not reachable from VLAN 10 (no allow rule)

### Inter-VLAN traffic not flowing
- Verify `eth1.10` and `eth1.20` are UP on Pi: `ip -br addr`
- Check FORWARD chain default policy is `DROP` (correct) but the
  specific allow rules exist: `sudo iptables -L ufw-user-forward -n -v`
- Check NAT counters incrementing: `sudo iptables -t nat -L POSTROUTING -n -v`
- Tcpdump on Pi to see if packets arrive: `sudo tcpdump -i eth1.20 -n`
