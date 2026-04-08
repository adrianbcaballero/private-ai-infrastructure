# Architecture

## Overview
This infrastructure follows a zero-trust-adjacent design 
where no internal services are directly exposed to the internet.
All remote access is funneled through a single WireGuard VPN 
endpoint running on a Raspberry Pi 3B+ (aegis).

## Components

### aegis — Security Gateway (VLAN 30 DMZ)
Raspberry Pi 3B+ acting as the network's single public 
facing device. Runs WireGuard VPN, Pi-hole DNS, Fail2ban, 
and UFW firewall. The only port open to the internet is 
UDP 51820 (WireGuard).

### aeglero-ai — AI Inference Server (VLAN 10 Production)
Bare metal Ubuntu Server running llama.cpp with CUDA for 
local AI inference. Dual GPU tensor splitting across GTX 1080 
and GTX 1660. Never directly exposed to the internet.

### CABALLERO-MAIN — Admin Workstation (VLAN 20 Admin)
Windows 10 desktop used for development, server management, 
and AI assisted coding via Continue.dev.

### EdgeSwitch 8XP — Managed Switch
Ubiquiti 8-port managed gigabit switch. VLAN segmentation 
pending configuration.

## Network Flow
1. Remote device connects via WireGuard to aegis
2. Authenticated device joins internal network tunnel
3. Device can reach aeglero-ai directly
4. All traffic stays within encrypted tunnel

## VLAN Design 
- VLAN 10 — Production — aeglero-ai
- VLAN 20 — Admin — aeglero-admin
- VLAN 30 — DMZ — aegis
- VLAN 40 — Home — untrusted devices