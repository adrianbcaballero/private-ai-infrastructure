# UFW Setup

Procedure for installing and enabling UFW on aegis. For the
applied rule set see [../network/ufw-rules.md](../network/ufw-rules.md).

## Install
```
sudo apt update
sudo apt install ufw
```

## Verify initial state
UFW ships inactive. Confirm before touching rules:
```
sudo ufw status
```

## Set default policy
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

## Apply rules
Add SSH and service rules BEFORE enabling — locking yourself out
of a remote host is the most common UFW failure mode.
```
sudo ufw allow from 192.168.1.0/24 to any port 2222 proto tcp
sudo ufw allow 51820/udp
sudo ufw allow from 192.168.1.0/24 to any port 53
sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp
```

## Enable
```
sudo ufw enable
```

## Verify
```
sudo ufw status verbose
sudo ufw status numbered
```

## Maintenance
- Rules persist across reboots automatically.
- Delete a rule by number: `sudo ufw delete <n>`
- Full reset if you need to start clean: `sudo ufw reset`
- Reload after manual config edits: `sudo ufw reload`

## Notes
- UFW is a front-end to iptables/nftables — `sudo iptables -L`
  still works for low-level inspection.
- Logging at medium verbosity is useful during initial bring-up:
  `sudo ufw logging medium`. Drop to `low` afterwards to keep
  syslog manageable.
