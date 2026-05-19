# Fail2ban Configuration

Runtime brute-force protection on aegis. Watches `sshd` logs and
auto-bans source IPs that fail SSH authentication repeatedly.

## Installed on
- aegis (Raspberry Pi 3B+)

## Configuration

`/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s
```

### What the defaults mean

- **maxretry = 3** — three failed SSH attempts within `findtime`
  triggers a ban.
- **findtime = 10m** — the window in which the failures must occur.
- **bantime = 1h** — duration of the ban once triggered.

These are deliberately strict. The threat model assumes the only
legitimate SSH client is the admin workstation using key auth —
password failures should not happen at all in normal operation, so
a low threshold is appropriate.

## Operational commands

```bash
# Current status (banned IPs, totals)
sudo fail2ban-client status sshd

# Show currently banned addresses
sudo fail2ban-client status sshd | grep "Banned IP"

# Manually unban an address (e.g., after a self-lockout)
sudo fail2ban-client set sshd unbanip <ip-address>

# Reload after config changes
sudo systemctl reload fail2ban
```

## Notes

- Fail2ban writes its bans as iptables rules. They appear alongside
  UFW rules but in separate chains (`f2b-sshd`).
- A self-induced lockout (typing the wrong password three times) is
  recoverable from a different source IP, the WireGuard tunnel, or
  physical console access.
- Logs at `/var/log/fail2ban.log` show ban/unban events with source
  IPs and timestamps.
