# UFW Firewall Rules

The Pi (aegis) is both a host firewall and an inter-VLAN
forwarding firewall. Three rule layers: INPUT (services on
the Pi), FORWARD (inter-VLAN routing), and NAT (egress source
rewriting).

## INPUT (services on the Pi itself)

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 51820 | UDP | Anywhere | WireGuard endpoint (public-facing) |
| 53 | UDP/TCP | 192.168.1.0/24 | DNS for WiFi / egress VLAN |
| 53 | UDP/TCP | 10.10.10.0/24 | DNS for AI VLAN |
| 53 | UDP/TCP | 10.20.20.0/24 | DNS for admin VLAN |
| 53 | UDP/TCP | wg0 (interface) | DNS for WireGuard clients |
| 2222 | TCP | 10.20.20.0/24 | SSH from admin VLAN |
| 2222 | TCP | wg0 (interface) | SSH from WireGuard clients |
| 80 | TCP | 10.20.20.0/24 | Pi-hole admin from admin VLAN |
| (default) | all | Anywhere | DENY |

## FORWARD (inter-VLAN routing through the Pi)

| Ingress | Egress | Source | Destination | Port | Purpose |
|---|---|---|---|---|---|
| eth1.10 | eth0 | any | any | any | VLAN 10 → internet |
| eth1.20 | eth0 | any | any | any | VLAN 20 → internet |
| eth1.20 | eth1.10 | 10.20.20.0/24 | 10.10.10.10 | tcp/22 | Admin SSH to AI |
| eth1.20 | eth1.10 | 10.20.20.0/24 | 10.10.10.10 | tcp/3000 | Admin Open WebUI |
| wg0 | eth1.10 | any | 10.10.10.10 | tcp/3000 | VPN clients → Open WebUI |
| (default) | — | — | — | — | DENY (routed) |

## NAT (POSTROUTING)

Configured in `/etc/ufw/before.rules`:

| Source | Outgoing | Action |
|---|---|---|
| 10.10.10.0/24 | eth0 | MASQUERADE |
| 10.20.20.0/24 | eth0 | MASQUERADE |

This rewrites outbound packets from VLAN 10/20 to use the
Pi's egress IP, so Spectrum can route reply traffic back.

## Configuration Reference

### Default policies
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed
```

In `/etc/default/ufw`:
```
DEFAULT_FORWARD_POLICY="DROP"
```

### INPUT rules
```bash
sudo ufw allow 51820/udp
sudo ufw allow from 192.168.1.0/24 to any port 53
sudo ufw allow from 10.10.10.0/24 to any port 53
sudo ufw allow from 10.20.20.0/24 to any port 53
sudo ufw allow in on wg0 to any port 53
sudo ufw allow from 10.20.20.0/24 to any port 2222 proto tcp
sudo ufw allow in on wg0 to any port 2222 proto tcp
sudo ufw allow from 10.20.20.0/24 to any port 80 proto tcp
```

### FORWARD (route allow) rules
```bash
sudo ufw route allow in on eth1.10 out on eth0
sudo ufw route allow in on eth1.20 out on eth0
sudo ufw route allow in on eth1.20 out on eth1.10 proto tcp from 10.20.20.0/24 to 10.10.10.10 port 22
sudo ufw route allow in on eth1.20 out on eth1.10 proto tcp from 10.20.20.0/24 to 10.10.10.10 port 3000
sudo ufw route allow in on wg0 out on eth1.10 proto tcp to 10.10.10.10 port 3000
```

### NAT rules
Add to the top of `/etc/ufw/before.rules`, above `*filter`:
```
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.20.20.0/24 -o eth0 -j MASQUERADE
COMMIT
```

### Activate
```bash
sudo ufw enable
```

### Verify
```bash
sudo ufw status verbose
sudo ufw status numbered
sudo iptables -L ufw-user-forward -n -v
sudo iptables -t nat -L POSTROUTING -n -v
```
