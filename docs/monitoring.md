# Network Monitoring (LibreNMS)

SNMP-based observability layer for the homelab. LibreNMS runs in
Docker on `aeglero-host` (VLAN 10) and polls the three core
infrastructure devices: aegis (Pi), aeglero-host (self), and the
EdgeSwitch. Alerts route to a Discord webhook for off-network
notification.

## Deployment

### Stack
Four containers managed via `docker compose`:

| Service | Image | Role |
|---|---|---|
| `librenms` | `librenms/librenms:latest` | Web UI (nginx + PHP-FPM) and Laravel scheduler |
| `dispatcher` | `librenms/librenms:latest` | Sidecar dispatcher — handles all device polling and alert evaluation |
| `db` | `mariadb:11.2` | LibreNMS data store |
| `redis` | `redis:7-alpine` | Locks and queues used by the dispatcher |


### File layout

```
/opt/librenms/
├── docker-compose.yml     # Stack definition
├── .env                   # MariaDB + LibreNMS secrets (mode 600)
├── db/                    # MariaDB persistent volume
└── librenms/              # LibreNMS state (RRDs, logs, config)
```

### Network
Web UI exposed on host port `8000`. Reachable at
`http://10.10.10.10:8000` from the admin VLAN and via WireGuard.


## SNMP Configuration (per device)

All devices use a shared **read-only community string**, set
locally — not the default `public`. SNMP versions vary by device
firmware capability:

| Device | IP | SNMP version | Notes |
|---|---|---|---|
| aegis (Pi) | 10.20.20.1 | v2c | Modern Debian snmpd, minimal LibreNMS-compatible config |
| aeglero-host | 10.10.10.10 | v2c | Ubuntu snmpd, same config pattern |
| EdgeSwitch 8XP | 192.168.1.20 | **v1 only** | Firmware v1.4.1 (2018) lacks v2c support |


## Alert Delivery (LibreNMS → Discord)

LibreNMS's alert system has three layers, all of which must be
configured:

1. **Alert Rules** — define conditions (e.g., `macros.device_down = 1`)
2. **Alert Operations** — bridge rules to transports with escalation
3. **Alert Transports** — physical delivery channels (Discord, email, etc.)

A single transport with the "Default Alert Transport" flag is
**not sufficient** by itself in current LibreNMS versions — rules
also need an Operation assigned that maps to one or more transports.
Otherwise alerts fire silently into the alert history with no
delivery.


### Rules enabled with Discord delivery

| Rule | Severity | Why enabled |
|---|---|---|
| Device Down (SNMP unreachable) | Critical | Primary "is it alive" detector |
| Device rebooted | Critical | Uptime reset signals reboot |
| Linux High Memory Usage ≥ 90% | Warning | Resource exhaustion early warning |
| Port utilisation over threshold | Critical | Saturation detection |


## Architecture diagram reference

The monitoring path appears in `architecture.png` as an SNMP-poll
line from `aeglero-host` to each monitored device. See
[`architecture.md`](architecture.md) for the broader network
topology and [`inter-vlan-routing.md`](inter-vlan-routing.md) for
the Pi's routing layer that makes this cross-VLAN polling work.
