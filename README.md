# server-bootstrap

Idempotent, re-runnable setup for a fresh Ubuntu VPS, with a dry-run mode and every step explained.

**Status: early scaffold. The script does nothing yet. Do not run it on a server expecting hardening.**

The plan is a single dependency-free bash script (no Ansible) that a reader can audit top to bottom: a non-root sudo user, SSH hardening applied last and verified, UFW, fail2ban, unattended-upgrades, Docker, Caddy, swap and log rotation. None of that exists yet. This repo currently holds only the command line (`--help`, `--version`, `--dry-run`) and its test.

## Try the current state

```bash
./bootstrap.sh --help
bash tests/test_cli.sh
```

## License

MIT, see [LICENSE](LICENSE).
