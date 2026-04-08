# Threat Model

## Assets Being Protected
- Local AI inference server (aeglero-ai)
- Development environment and code
- Network infrastructure
- Potential PHI in AI queries (Aeglero EMR context)

## Threats and Mitigations

| Threat | Mitigation |
|---|---|
| Brute force SSH | Fail2ban, key only auth, port 2222 |
| Unauthorized remote access | WireGuard VPN, single entry point |
| Lateral movement from home devices | VLAN segmentation (planned) |
| DNS hijacking / tracking | Pi-hole DNS filtering |
| Physical network intrusion | Managed switch with port security |
| Data exfiltration via AI queries | Local inference only, no cloud API |
| Compromised IoT/home device | VLAN 40 isolation, no server access |

## Trust Zones
| Zone | VLAN | Devices | Trust Level |
|---|---|---|---|
| Internet | — | External | Untrusted |
| DMZ | 30 | Aegis | Limited |
| Production | 10 | aeglero-ai | High |
| Admin | 20 | Desktop | Trusted |
| Home | 40 | IoT, phones | Untrusted |

## Attack Surface
Only one port is exposed to the internet:
- UDP 51820 — WireGuard VPN

All other services are internal only and unreachable 
without a valid WireGuard key.