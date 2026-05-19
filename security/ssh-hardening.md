# SSH Hardening

Configuration applied to aegis (Pi) and aeglero-host. SSH is the
primary administrative access path and must be locked down accordingly.

## Changes to /etc/ssh/sshd_config

```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

### Rationale

- **Port 2222** — non-default port. Reduces noise from automated
  scanners hitting port 22; not a real security control on its own
  but combined with Fail2ban it cuts log volume substantially.
- **PermitRootLogin no** — direct root SSH disabled. Operators
  connect as an unprivileged user and `sudo` for elevated tasks.
- **PasswordAuthentication no** — passwords disabled entirely.
  Authentication is via SSH key only.
- **PubkeyAuthentication yes** — explicit enable (already the
  default on modern OpenSSH, but stated for clarity).

## sshd_config.d overrides

Modern OpenSSH reads `/etc/ssh/sshd_config.d/*.conf` and these can
silently override the main config. On Ubuntu Server, cloud-init
typically drops `50-cloud-init.conf` which may set
`PasswordAuthentication yes`. **Audit and reconcile** before
trusting the main config:

```bash
sudo grep -r PasswordAuthentication /etc/ssh/
```

If `50-cloud-init.conf` enables password auth, edit it to `no` or
remove the line entirely.

## Apply changes

```bash
sudo sshd -t                      # syntax check before reload
sudo systemctl reload ssh        # reload sshd without dropping existing sessions
```

`sshd -t` is critical — a syntax error followed by a `restart`
will leave you locked out.

## Key management

- Each operator device gets its own keypair. Shared keys make
  rotation and revocation harder.
- Generate keys with:
  ```bash
  ssh-keygen -t ed25519 -C "<purpose-or-host>"
  ```
- Public keys go in `~/.ssh/authorized_keys` on the target host,
  with file mode `600` and parent directory `700`.

## Access restrictions

SSH is further gated by UFW (see
[`../network/ufw-rules.md`](../network/ufw-rules.md)):
- Port 2222 inbound: allowed only from the admin VLAN
  (10.20.20.0/24) and the WireGuard tunnel (`wg0`)
- Brute-force attempts caught by Fail2ban (see
  [`fail2ban.md`](fail2ban.md))

The combination of key-only auth, non-default port, source-IP
allowlist, and brute-force ban means a remote attacker would need
to (a) get past WireGuard, OR (b) be on the admin VLAN, AND
(c) possess a valid private key to even attempt access.
