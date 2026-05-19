# Inter-VLAN Routing on aegis

How the Raspberry Pi (aegis) functions as an L3 router between
VLANs, including kernel config, interface setup, NAT, and the
firewall rules that govern which inter-VLAN flows are permitted.

## Interface Layout

```
eth0          → built-in NIC, untagged VLAN 30, IP 192.168.1.X
eth1          → USB ethernet, tagged trunk, no IP
eth1.10       → VLAN 10 sub-interface, IP 10.10.10.1/24
eth1.20       → VLAN 20 sub-interface, IP 10.20.20.1/24
wg0           → WireGuard tunnel, IP 10.0.0.1/24
```

## Kernel and Module Config

IPv4 forwarding (`/etc/sysctl.d/99-ip-forward.conf`):
```
net.ipv4.ip_forward=1
```

802.1Q kernel module (`/etc/modules`):
```
8021q
```

## NetworkManager Connection Profiles

The Pi runs NetworkManager (default on Pi OS Bookworm). VLAN
sub-interfaces are managed as NM connections so they auto-start
on boot.

```bash
# eth1 as bare trunk parent
nmcli con add type ethernet con-name eth1-trunk ifname eth1 \
    ipv4.method disabled ipv6.method disabled

# VLAN 10 sub-interface
nmcli con add type vlan con-name eth1.10 ifname eth1.10 \
    dev eth1 id 10 \
    ipv4.method manual ipv4.addresses 10.10.10.1/24 \
    ipv6.method disabled

# VLAN 20 sub-interface
nmcli con add type vlan con-name eth1.20 ifname eth1.20 \
    dev eth1 id 20 \
    ipv4.method manual ipv4.addresses 10.20.20.1/24 \
    ipv6.method disabled
```

No default gateway is set on the VLAN sub-interfaces — the Pi's
default route stays via `eth0 → 192.168.1.1` (Spectrum).

## NAT for Egress

Source NAT (MASQUERADE) is configured in `/etc/ufw/before.rules`
above the `*filter` section:

```
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.20.20.0/24 -o eth0 -j MASQUERADE
COMMIT
```

This rewrites the source IP of outbound packets from VLAN 10/20
to the Pi's egress IP, so the Spectrum router (which knows
nothing about the VLAN subnets) can correctly return reply
traffic to the Pi for reverse-NAT.

## Default Forward Policy

`/etc/default/ufw`:
```
DEFAULT_FORWARD_POLICY="DROP"
```

Combined with:
```bash
sudo ufw default deny routed
```

This enforces deny-by-default forwarding. Every permitted
inter-VLAN flow must be explicitly allowed.

## Firewall Rules

### INPUT (services on the Pi itself)
| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 51820 | UDP | Anywhere | WireGuard endpoint |
| 53 | TCP/UDP | 192.168.1.0/24 | DNS for WiFi devices |
| 53 | TCP/UDP | 10.10.10.0/24 | DNS for AI VLAN |
| 53 | TCP/UDP | 10.20.20.0/24 | DNS for admin VLAN |
| 53 | TCP/UDP | wg0 interface | DNS for VPN clients |
| 2222 | TCP | 10.20.20.0/24 | SSH from admin VLAN |
| 2222 | TCP | wg0 interface | SSH from VPN clients |
| 80 | TCP | 10.20.20.0/24 | Pi-hole admin from admin VLAN |

### FORWARD (inter-VLAN routing)
| In | Out | Source | Destination | Port | Purpose |
|---|---|---|---|---|---|
| eth1.10 | eth0 | any | any | any | VLAN 10 → internet |
| eth1.20 | eth0 | any | any | any | VLAN 20 → internet |
| eth1.20 | eth1.10 | 10.20.20.0/24 | 10.10.10.10 | tcp/22 | Admin SSH to AI |
| eth1.20 | eth1.10 | 10.20.20.0/24 | 10.10.10.10 | tcp/3000 | Admin Open WebUI |
| wg0 | eth1.10 | any | 10.10.10.10 | tcp/3000 | VPN client Open WebUI |

### Implicit deny
Anything not matching an allow rule is dropped by the FORWARD
chain's default DROP policy. This is the security boundary.

## Recovery / Rebuild

If the Pi needs to be re-imaged:
1. Restore `/etc/sysctl.d/99-ip-forward.conf`, `/etc/modules`
2. Recreate NM VLAN connections (commands above)
3. Restore `/etc/ufw/before.rules` (NAT block)
4. Re-apply the INPUT and FORWARD rules via `ufw allow` / `ufw route allow`
5. `sudo ufw enable`
6. Verify with the commands in the previous section

A full backup of `/etc` should be kept off-Pi to make this
trivially repeatable.
