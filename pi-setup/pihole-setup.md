# Pi-hole Setup

Installed on aegis (Raspberry Pi 3B+) to provide network-wide
DNS filtering and ad/tracker blocking.

## Install
```
curl -sSL https://install.pi-hole.net | bash
```

The official installer is interactive and walks through:
- Static IP confirmation
- Upstream DNS resolver selection
- Default blocklist setup
- Web admin interface enable
- Admin password generation

## Configuration choices
- **Upstream DNS:** Cloudflare (1.1.1.1 / 1.0.0.1) — fast and
  honors a no-logging stance. Quad9 is a reasonable alternative
  if you want malware blocklisting at the resolver layer.
- **Static IP:** assigned via router DHCP reservation rather
  than configured directly on the Pi. Easier to revert and keeps
  the Pi's interface config stock.
- **Web admin:** port 80, internal network only (firewalled by
  UFW — see [../network/ufw-rules.md](../network/ufw-rules.md)).
- **Query logging:** enabled. Useful for verifying that clients
  are actually resolving through Pi-hole.

## Post-install
Change the default admin password:
```
pihole -a -p
```

Point clients at the Pi for DNS. Two options:
1. Set the Pi's IP as the network DNS server in the router DHCP
   config (covers every client automatically).
2. Set DNS per-device on clients that should be filtered.

## Verify
```
pihole status
pihole -q google.com
dig @192.168.1.XXX google.com
```

A device using Pi-hole should show the Pi's IP as the resolver
in `nslookup` / `dig`. Blocked domains return `0.0.0.0`.

## Maintenance
```
pihole -up      # update Pi-hole itself
pihole -g       # refresh gravity (blocklists)
pihole -c       # live query dashboard in terminal
```

## Notes
- Some smart-home devices (Chromecast, certain IoT) hardcode
  8.8.8.8 / 1.1.1.1 and bypass Pi-hole. Router-level NAT
  redirect of all outbound port 53 traffic is the workaround,
  but it breaks DNS-over-HTTPS clients. Pick your battles.
- Pi-hole won't filter DoH/DoT traffic out of the box — those
  resolve outside the DNS layer.
