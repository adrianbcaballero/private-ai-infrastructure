# Architecture

## Overview
This infrastructure follows a zero-trust-adjacent design where
no internal services are directly exposed to the internet, and
no trust is granted between VLANs without explicit firewall
rules. The Raspberry Pi (aegis) acts as both the perimeter
gateway and the L3 router between internal VLANs — a
"router-on-a-stick" topology.

All remote access is funneled through a single WireGuard VPN
endpoint, and all inter-VLAN traffic is gated by a stateful
firewall.

## Components

### aegis — Security Gateway and L3 Router (VLAN 30 + trunk)
Raspberry Pi 3B+ with two network interfaces:

- **eth0 (built-in)** — untagged on VLAN 30, the egress segment shared
  with the Spectrum router. Carries the Pi's primary IP and is the
  outbound path for all internet traffic.
- **eth1 (USB ethernet)** — 802.1Q trunk port carrying VLAN 10 and
  VLAN 20 tagged. Two sub-interfaces (`eth1.10`, `eth1.20`) terminate
  on the Pi as the gateway for each VLAN.

Services running on the Pi:
- WireGuard VPN — UDP 51820, the only port exposed to the public internet
- Pi-hole DNS — listens on all interfaces, serves all VLANs
- UFW (stateful firewall) — INPUT, FORWARD, and NAT rules
- Fail2ban — SSH brute-force protection
- IP forwarding + MASQUERADE — NAT egress for isolated VLANs

### aeglero-host — AI Inference Server (VLAN 10)
Bare-metal Ubuntu Server running llama.cpp with CUDA for local
AI inference. Dual GPU tensor splitting across GTX 1080 and
GTX 1660 Super. Lives entirely within VLAN 10 — structurally
isolated from untrusted devices, reachable only via the Pi
router and only on explicitly allowed ports.

### aeglero-admin — Admin Workstation (VLAN 20)
Windows desktop used for development, server management, and
AI-assisted coding via Continue.dev. Wired into VLAN 20 as the
sole administrative client. Has firewall-allowed access to
SSH and Open WebUI on the AI server.

### EdgeSwitch 8XP — Managed Switch
Ubiquiti 8-port managed gigabit switch with 802.1Q VLAN tagging.
Switch management interface lives on VLAN 30 so it remains
reachable from the egress segment.

## VLAN and Subnet Design

| VLAN | Purpose | Subnet | Gateway | Notes |
|---|---|---|---|---|
| 10 | AI Inference | 10.10.10.0/24 | 10.10.10.1 (Pi eth1.10) | Isolated, no inbound from WiFi |
| 20 | Admin | 10.20.20.0/24 | 10.20.20.1 (Pi eth1.20) | Sole administrative VLAN |
| 30 | Egress | 192.168.1.0/24 | 192.168.1.1 (Spectrum) | Shared with WiFi and Spectrum |
| (tunnel) | WireGuard | 10.0.0.0/24 | 10.0.0.1 (Pi wg0) | Remote VPN clients |

## Physical Port Topology (EdgeSwitch 8XP)

| Port | Role | VLAN Config |
|---|---|---|
| 1 | Spectrum router uplink | Untagged VLAN 30 |
| 2 | aeglero-host | Untagged VLAN 10 |
| 3 | aeglero-admin | Untagged VLAN 20 |
| 4 | aegis (Pi built-in eth0) | Untagged VLAN 30 |
| 5 | aegis (Pi USB-eth eth1) | Tagged trunk, VLAN 10 + VLAN 20 |
| 6 | Other room | Untagged VLAN 30 |
| 7-8 | Free | Untagged VLAN 1 (unused) |

## Traffic Flows

### Admin → AI Server (e.g., SSH)
```
aeglero-admin (10.20.20.10)
  → switch Port 3 (untagged VLAN 20)
  → switch internal VLAN 20 broadcast domain
  → switch Port 5 (tagged VLAN 20)
  → Pi eth1.20 (10.20.20.1)
  → kernel routing → eth1.10 (10.10.10.1)
  → switch Port 5 (tagged VLAN 10)
  → switch Port 2 (untagged VLAN 10)
  → aeglero-host (10.10.10.10)
```
The Pi's FORWARD chain validates this is an allowed flow
(admin→AI on tcp/22 or tcp/3000) before forwarding.

### AI Server → Internet (e.g., HuggingFace model pull)
```
aeglero-host (10.10.10.10)
  → Pi eth1.10 (default gateway)
  → kernel routing → eth0 (192.168.1.x)
  → MASQUERADE (source rewritten to Pi's egress IP)
  → switch Port 4 → switch Port 1 (untagged VLAN 30)
  → Spectrum router → internet
```

### WiFi Device → Open WebUI
```
WiFi device (192.168.1.x, VLAN 30)
  → Spectrum router → switch (VLAN 30)
  → no route to 10.10.10.0/24 exists at Spectrum
  → DROP
```
WiFi is structurally unable to reach VLAN 10. No firewall
rule is required to enforce this.

### Remote VPN client → Open WebUI
```
phone on cellular → public internet
  → Spectrum WAN → UDP 51820 forward → aegis WireGuard
  → decrypt → wg0 (10.0.0.x)
  → kernel routing → eth1.10
  → Pi FORWARD chain validates (VPN → AI:3000 allowed)
  → aeglero-host (10.10.10.10:3000)
```

## Security Enforcement Layers

1. **Physical / L2** — VLANs separate broadcast domains; WiFi
   cannot ARP for AI server.
2. **L3 routing** — Different subnets per VLAN; non-Pi devices
   have no route to other VLAN subnets.
3. **Stateful firewall** — Pi's `ufw route allow` rules enforce
   exactly which inter-VLAN flows are permitted, by source IP +
   destination IP + protocol + port.
4. **NAT** — Source-IP rewriting on egress hides internal subnet
   structure from upstream networks.
5. **Pi INPUT firewall** — Services on the Pi itself (SSH,
   DNS, Pi-hole admin) are restricted by source VLAN.
6. **Application auth** — SSH key-only, Pi-hole admin password,
   Open WebUI auth on top of the network layer.

## Why Pi-as-router instead of a dedicated L3 device

The Spectrum ISP router cannot do inter-VLAN routing. Rather
than introduce a separate router/firewall appliance, the Pi —
already required for WireGuard and Pi-hole — was extended with
a USB-ethernet adapter to serve as an 802.1Q trunk terminator.
This achieves true L3 segmentation with hardware already in use.

Tradeoffs:
- **Single point of failure** — if the Pi goes down, all
  inter-VLAN traffic stops. Mitigated by simple recoverability
  (re-flash SD card from backup).
- **Throughput ceiling** — Pi 3B+ USB 2.0 bus caps practical
  throughput at ~300 Mbps. Sufficient for chat, SSH, and DNS;
  becomes a bottleneck only during large model downloads.
- **Complexity** — VLAN sub-interfaces, NAT, and firewall rules
  must be coordinated. Documented in `docs/inter-vlan-routing.md`.

See [inter-vlan-routing.md](inter-vlan-routing.md) for the
implementation detail of the routing and firewall layer.
