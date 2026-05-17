# Threat Model

## Assets Being Protected
- Local AI inference server (aeglero-ai) and any sensitive
  data it processes (potential PHI in regulated contexts)
- Development environment and code
- Network infrastructure (switch, gateway)
- WireGuard tunnel keys and SSH private keys

## Threats and Mitigations

| Threat | Mitigation | Enforcement Layer |
|---|---|---|
| Brute force SSH | Fail2ban + key-only auth + non-standard port | App + perimeter |
| Unauthorized remote access | WireGuard VPN as sole public entry point | L3 perimeter |
| Lateral movement from home WiFi | True L3 VLAN segmentation; AI VLAN unreachable | L2 + L3 + firewall |
| Compromised admin workstation reaching AI | Limited to explicit ports (22, 3000) via Pi firewall | Stateful firewall |
| Compromised IoT/WiFi device | No route to VLAN 10/20 exists at any router | L3 routing |
| DNS hijacking / tracking | Pi-hole DNS filtering, all VLANs use it | App layer |
| Physical network intrusion (rogue device) | Managed switch with explicit VLAN port assignments | L2 (VLAN tagging) |
| Data exfiltration via AI queries | Local inference only, no cloud API egress | App layer |
| Switch management hijack | Management VLAN bound to egress segment, not exposed | L2 |
| ARP spoofing within VLAN | Limited blast radius (only same-VLAN devices affected) | L2 |

## Trust Zones

| Zone | VLAN | Devices | Trust Level | Can reach |
|---|---|---|---|---|
| Internet | — | External | Untrusted | WireGuard only |
| Egress | 30 | Spectrum, Pi eth0, WiFi clients, other-room | Limited | Internet, Pi DNS |
| Admin | 20 | aeglero-admin | Trusted | AI server (limited ports), Pi services, internet |
| AI Inference | 10 | aeglero-ai | High-value | Pi DNS, internet (NAT'd), nothing else inbound |
| WireGuard tunnel | — | Authenticated VPN clients | Conditionally trusted | AI Open WebUI, Pi SSH/DNS |

## Attack Surface

### Public-facing (internet)
- UDP 51820 — WireGuard VPN (one port, encrypted, key-authenticated)

### From compromised WiFi device
- DNS queries to Pi-hole (port 53) — limited risk, can be poisoned
- Nothing else: no L2 path to admin or AI VLANs, no L3 route exists

### From compromised admin workstation
- Tcp/22 and tcp/3000 to AI server (explicitly allowed)
- SSH and Pi-hole admin on the Pi (allowed)
- Cannot directly reach 10.10.10.x except on allowed ports

### From compromised AI server
- DNS queries to Pi-hole
- Outbound internet egress (NAT'd through Pi → Spectrum)
- Cannot initiate connections back to admin VLAN (no allow rule)

## Defense in Depth Layers

1. **Physical / L2** — Managed switch with strict VLAN port
   assignments. WiFi devices physically cannot place packets
   on the AI or admin VLAN broadcast domains.
2. **L3 routing** — Spectrum router has no route to internal
   VLAN subnets. The only device that knows how to route between
   VLANs is the Pi.
3. **Stateful firewall** — Pi's UFW route allow rules permit
   exactly which inter-VLAN flows can occur, by 5-tuple
   (src IP, dst IP, src port, dst port, proto).
4. **NAT** — Egress IP rewriting hides internal subnet
   structure from upstream and prevents return-path leaks.
5. **Service-level** — SSH key auth, Pi-hole admin password,
   Open WebUI authentication, Fail2ban brute-force protection.
6. **Operational** — Distinct trust assumptions per VLAN; no
   shared keys between admin and AI server beyond the
   intentional admin SSH path.

## Known Limitations

- **Pi as single point of failure** for inter-VLAN routing.
  Mitigated by ease of rebuild from backup `/etc/`.
- **No IDS/IPS** at the inter-VLAN boundary. Could add Suricata
  or similar on the Pi at a throughput cost.
- **Pi 3B+ throughput ceiling** (~300 Mbps practical). Not a
  bottleneck for typical traffic; would matter only during
  large model pulls or backups.
- **Trust of admin VLAN is broad** — admin workstation can
  reach AI server on tcp/22 and tcp/3000. Compromise of admin
  workstation does grant control of the AI server, accepted
  as the operational model.
