# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-11

### Added

- Step framework under `lib/` and `steps/`, with `--list`, `--only`, `--skip`,
  and a change counter that makes re-runs report "No changes were needed".
- Steps: `user`, `swap`, `unattended-upgrades`, `fail2ban`, `log-rotation`,
  `ufw`, `docker`, `proxy` (Caddy or Nginx+certbot), optional `monitoring`,
  and `ssh` hardening last (keys-only, warning + confirmation).
- Dry-run mode that prints planned changes and writes nothing.
- Container behaviour tests (`tests/test_steps.sh`) and CLI tests.
- ADRs: plain shell over Ansible, SSH last, Caddy over Nginx.
- `SECURITY.md` section on what this does **not** secure.
- `QA.md`, `TEST_REPORT.md`, the step-list page under `site/`, and a downloadable checklist.

### Known limits

- Ubuntu 24.04 only. 22.04 is refused: Caddy is not in its archive, so the proxy step failed there.
- Not yet run end to end on a real VPS. Service restarts, UFW enablement, swap creation
  and a live SSH reload are not exercised by the container tests.
