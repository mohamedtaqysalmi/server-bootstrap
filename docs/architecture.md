# Architecture

`bootstrap.sh` loads helpers from `lib/`, discovers `steps/NN-name.sh` in lexical order, and runs each `step_*` function. Steps that are already satisfied print `ok` and leave the system alone.

## Decision records

| ADR | Summary |
| --- | --- |
| [0001-shell-over-ansible.md](adr/0001-shell-over-ansible.md) | Plain bash over Ansible for a single auditable VPS script. |
| [0002-ssh-last.md](adr/0002-ssh-last.md) | SSH hardening is last, warned, confirmed, and verified. |
| [0003-caddy-over-nginx.md](adr/0003-caddy-over-nginx.md) | Caddy for automatic HTTPS instead of Nginx+certbot. |

## Step order

| Order | Step | Why this position |
| --- | --- | --- |
| 05 | user | Non-root account and key must exist before SSH locks passwords out. |
| 10 | swap | Memory headroom before installing services. |
| 20 | unattended-upgrades | Patching early, before exposing more services. |
| 30 | fail2ban | Ban hammering once SSH is the attack surface; port updated after SSH if needed. |
| 40 | log-rotation | Cap journal growth before long-running services. |
| 50 | ufw | Firewall before Docker/Caddy publish ports; SSH allowed before enable. |
| 60 | docker | Runtime for apps; log limits in daemon.json. |
| 70 | proxy | Caddy (default) or Nginx reverse proxy + TLS. |
| 80 | monitoring | Optional node exporter; off unless `ENABLE_MONITORING=1`. |
| 90 | ssh | Last. Warns about lockout, requires confirm, validates with `sshd -t` / `sshd -T`. |

## Dry-run

`--dry-run` sets `DRY_RUN=1`. Helpers print planned changes and never execute mutating commands through `run()`. Real runs must be root; dry-run may run as a normal user.
