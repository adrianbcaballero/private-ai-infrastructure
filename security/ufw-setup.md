# UFW Setup

Procedure for installing and enabling UFW on aegis. The applied rule
set lives in [`../network/ufw-rules.md`](../network/ufw-rules.md);
this document covers only the bring-up procedure.

## Install

```bash
sudo apt update
sudo apt install ufw
```

## Verify initial state

UFW ships inactive. Confirm before applying rules so you know the
baseline:

```bash
sudo ufw status
```

## Set default policies

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed
```

The `deny routed` default is critical for the inter-VLAN routing role
— it ensures the Pi forwards only what's explicitly allowed.

In `/etc/default/ufw`, confirm:

```
DEFAULT_FORWARD_POLICY="DROP"
```

## Apply rules

Add SSH and service rules **before** enabling UFW. Locking yourself
out of a remote host by enabling default-deny without an SSH allow
is the most common operator error.

Refer to [`../network/ufw-rules.md`](../network/ufw-rules.md) for the
full set of INPUT, FORWARD, and NAT rules used in this deployment.
At minimum, the SSH allow for the admin VLAN must exist before enable:

```bash
sudo ufw allow from 10.20.20.0/24 to any port 2222 proto tcp comment "SSH from admin VLAN"
sudo ufw allow 51820/udp comment "WireGuard"
```

## NAT (for inter-VLAN routing)

NAT rules go in `/etc/ufw/before.rules`, above the `*filter` section:

```
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.20.20.0/24 -o eth0 -j MASQUERADE
COMMIT
```

This rewrites outbound traffic from VLAN 10/20 so the upstream
Spectrum router (which has no route to those subnets) can correctly
return reply packets to the Pi.

## Enable

```bash
sudo ufw enable
```

## Verify

```bash
sudo ufw status verbose
sudo ufw status numbered
sudo iptables -L ufw-user-forward -n -v
sudo iptables -t nat -L POSTROUTING -n -v
```

The `ufw status verbose` output should show:
- `Status: active`
- `Default: deny (incoming), allow (outgoing), deny (routed)`
- All configured allow rules

## Maintenance

- Rules persist across reboots via UFW's own startup mechanism.
- Delete a rule by number: `sudo ufw delete <n>` (numbers from `ufw status numbered`).
- Reset to factory state: `sudo ufw reset` (clears all rules).
- Reload after manual config edits: `sudo ufw reload`.

## Notes

- UFW is a front-end for iptables / nftables. Direct inspection still
  works via `sudo iptables -L` for debugging.
- During initial bring-up, raise log verbosity:
  `sudo ufw logging medium`. Drop back to `low` afterward to keep
  syslog manageable in steady state.
- When editing `/etc/ufw/before.rules`, always `sudo ufw reload` to
  apply changes; the NAT block in particular is read only at reload
  time.
