# Network Reference

## VLANs and Subnets
| VLAN | Purpose | Subnet | Gateway |
|---|---|---|---|
| 10 | AI Inference | 10.10.10.0/24 | 10.10.10.1 (Pi eth1.10) |
| 20 | Admin | 10.20.20.0/24 | 10.20.20.1 (Pi eth1.20) |
| 30 | Egress / Home | 192.168.1.0/24 | 192.168.1.1 (Spectrum) |
| — | WireGuard tunnel | 10.0.0.0/24 | 10.0.0.1 (Pi wg0) |

## Device IPs
| Device | VLAN | IP | Notes |
|---|---|---|---|
| Spectrum router | 30 | 192.168.1.1 | ISP edge, NAT to internet |
| EdgeSwitch 8XP | 30 | 192.168.1.XXX | Web admin interface |
| aegis (Pi, eth0) | 30 | 192.168.1.XXX | Egress / management |
| aegis (Pi, eth1.10) | 10 | 10.10.10.1 | AI VLAN gateway |
| aegis (Pi, eth1.20) | 20 | 10.20.20.1 | Admin VLAN gateway |
| aegis (Pi, wg0) | tunnel | 10.0.0.1 | VPN tunnel endpoint |
| aeglero-ai | 10 | 10.10.10.10 | Open WebUI on :3000 |
| aeglero-admin | 20 | 10.20.20.10 | Windows workstation, wired |

## Switch Port Map
| Port | Device | VLAN Membership |
|---|---|---|
| 1 | Spectrum router uplink | Untagged VLAN 30 |
| 2 | aeglero-ai | Untagged VLAN 10 |
| 3 | aeglero-admin | Untagged VLAN 20 |
| 4 | aegis (eth0) | Untagged VLAN 30 |
| 5 | aegis (eth1 trunk) | Tagged VLAN 10, Tagged VLAN 20 |
| 6 | Other-room device | Untagged VLAN 30 |
| 7-8 | Free | Untagged VLAN 1 (unused) |

## Ports and Services
| Port | Protocol | Service | Reachable from |
|---|---|---|---|
| 51820 | UDP | WireGuard VPN | Public internet |
| 2222 | TCP | SSH (aegis) | Admin VLAN, WireGuard tunnel |
| 22 | TCP | SSH (aeglero-ai) | Admin VLAN, via Pi forward |
| 53 | UDP/TCP | Pi-hole DNS | All VLANs, WireGuard tunnel |
| 80 | TCP | Pi-hole admin | Admin VLAN only |
| 3000 | TCP | Open WebUI | Admin VLAN, WireGuard tunnel |

## Internet Egress Path
All VLAN 10 and VLAN 20 outbound traffic is NAT'd by the Pi
through eth0 to the Spectrum router. The Spectrum router sees
only the Pi's egress IP, not the internal VLAN addresses.

## Notes
- All `192.168.1.XXX` placeholders correspond to the real
  Spectrum-DHCP-assigned IPs documented privately. Static
  reservations are configured via Spectrum's admin panel.
- The switch management interface was migrated from VLAN 1 to
  VLAN 30 to ensure it remains reachable from the egress
  segment after VLAN 1 was emptied of physical ports.
