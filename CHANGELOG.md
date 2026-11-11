# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-11

### Added

- Step framework under `lib/` and `steps/`, with `--list`, `--only`, `--skip`,
  and a change counter that makes re-runs report "No changes were needed".
- Steps: `user`, `swap`, `unattended-upgrades`, `fail2ban`, `log-rotation`,
  `ufw`, `docker`, `proxy` (Caddy or Nginx+certbot), optional `monitoring`,
  and `ssh` hardening last (keys-only, warning + confirmation).
- Dry-run mode that prints planned changes and writes nothing.
- Container behaviour tests (`tests/test_steps.sh`) and CLI tests.
- ADR explaining why the tool is plain shell, not Ansible.
- `SECURITY.md` section on what this does **not** secure.
- `QA.md`, GitHub Pages sources under `docs/`, and a downloadable checklist.

## [Unreleased]

### Added

- Project scaffold and community/CI baseline (superseded by 0.1.0).
