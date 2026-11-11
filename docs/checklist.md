# server-bootstrap operator checklist

Print or save this before you touch a production-like VPS.

## Before you start

- [ ] Throwaway or recoverable Ubuntu 24.04 host
- [ ] Provider console / VNC available if SSH fails
- [ ] SSH public key ready (`BOOTSTRAP_SSH_PUBKEY` or root `authorized_keys`)
- [ ] Optional: `BOOTSTRAP_DOMAIN`, `BOOTSTRAP_ACME_EMAIL`, `BOOTSTRAP_PROXY=caddy|nginx|none`
- [ ] Optional: `ENABLE_MONITORING=1` if you want node exporter

## Run order

- [ ] `./bootstrap.sh --list` — confirm steps and reasons
- [ ] `sudo ./bootstrap.sh --dry-run` — read the plan; change nothing
- [ ] `sudo ./bootstrap.sh --skip ssh` — apply everything except SSH hardening
- [ ] Open a **second** session as `BOOTSTRAP_USER` with the key
- [ ] `sudo BOOTSTRAP_CONFIRM_SSH=1 ./bootstrap.sh --only ssh` — harden SSH last
- [ ] Keep the original session open until the new login is proven
- [ ] `sudo ./bootstrap.sh` again — expect "No changes were needed"

## Verify

- [ ] Password SSH and root SSH are refused
- [ ] UFW active; SSH / 80 / 443 allowed
- [ ] fail2ban installed; sshd jail present
- [ ] unattended-upgrades enabled; automatic reboot still off
- [ ] Docker installed; daemon log size capped
- [ ] Caddy or Nginx serving placeholder or your domain
- [ ] Swap active (on real VPS, not inside a container)
- [ ] Journal size capped; logrotate present

## Remember what this does not cover

See [SECURITY.md](../SECURITY.md): cloud perimeter, app security, secrets
management, IDS/EDR, compliance evidence, and lockout recovery are out of scope.
