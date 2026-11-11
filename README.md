# server-bootstrap

Idempotent, re-runnable setup for a fresh Ubuntu 24.04 VPS, with a
dry-run mode and every step explained.

**Status: v0.1.0.** Plain bash on purpose ([ADR 0001](docs/adr/0001-shell-over-ansible.md)).
SSH hardening runs **last**, after a lockout warning. Read
[SECURITY.md](SECURITY.md) for what this does **not** secure.

## Quick start

```bash
./bootstrap.sh --list
sudo ./bootstrap.sh --dry-run
sudo BOOTSTRAP_SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" ./bootstrap.sh --skip ssh
# prove key login in a second session, then:
sudo BOOTSTRAP_CONFIRM_SSH=1 ./bootstrap.sh --only ssh
```

## Steps

| Step | Protects against |
| ---- | ---------------- |
| `user` | Day-to-day work as root |
| `swap` | OOM killer on small VPS memory |
| `unattended-upgrades` | Unpatched known vulnerabilities |
| `fail2ban` | SSH password-guessing bots |
| `log-rotation` | Logs filling the disk |
| `ufw` | Unexpected inbound exposure |
| `docker` | Unisolated workloads / unbounded container logs |
| `proxy` | Serving apps without TLS (Caddy or Nginx) |
| `monitoring` | Blindness to CPU/mem/disk pressure (optional) |
| `ssh` | Password auth and root login (applied last) |

Optional knobs: `BOOTSTRAP_PROXY=caddy|nginx|none`, `BOOTSTRAP_DOMAIN`,
`ENABLE_MONITORING=1`. Full list: `./bootstrap.sh --help`.

## Docs

- Operator checklist (downloadable): [docs/checklist.md](docs/checklist.md)
- Pages site source: [site/](site/)
- QA before release: [QA.md](QA.md)
- Contributing / local checks: [CONTRIBUTING.md](CONTRIBUTING.md)

## Tests

```bash
docker run --rm -v "$PWD":/work -w /work ubuntu:24.04 bash tests/test_cli.sh
docker run --rm -e BOOTSTRAP_TEST_IN_CONTAINER=1 -v "$PWD":/src:ro -w /src \
  ubuntu:24.04 bash tests/test_steps.sh
```

Never run the real script on a machine you care about while experimenting.
Use a container or a throwaway VM.

## License

MIT, see [LICENSE](LICENSE). Owner: Mohamed-Taqy Salmi.
