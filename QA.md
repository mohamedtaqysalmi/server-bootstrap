# QA checklist for server-bootstrap

Use this before tagging a release or merging a step change.

## Static checks

- [ ] `shellcheck` clean on every tracked `*.sh`
- [ ] `shfmt -d` clean on every tracked `*.sh`
- [ ] `bash tests/test_cli.sh` passes (help, version, list, bad flags)
- [ ] CI green on the PR

## Container behaviour

Run on a disposable host only:

```bash
docker run --rm -e BOOTSTRAP_TEST_IN_CONTAINER=1 -v "$PWD":/src:ro -w /src \
  ubuntu:24.04 bash tests/test_steps.sh
```

- [ ] Dry-run exits 0 and changes no files / packages
- [ ] First real run (SSH skipped in CI container) exits 0
- [ ] Second real run reports "No changes were needed"
- [ ] Unsupported OS / non-root paths still fail clearly

## Manual VPS pass (before trusting SSH hardening)

On a throwaway Ubuntu 24.04 VM:

- [ ] `sudo ./bootstrap.sh --dry-run` shows the intended plan
- [ ] Export `BOOTSTRAP_SSH_PUBKEY` (or install a root key) and run without SSH:
      `sudo BOOTSTRAP_CONFIRM_SSH=0 ./bootstrap.sh --skip ssh`
- [ ] Confirm login as `BOOTSTRAP_USER` with the key in a **second** session
- [ ] Re-run with `BOOTSTRAP_CONFIRM_SSH=1` so SSH hardening applies last
- [ ] Confirm password auth and root login are refused
- [ ] Confirm UFW is active and allows SSH / 80 / 443
- [ ] Confirm fail2ban, unattended-upgrades, Docker, and the proxy are present
- [ ] Re-run the full script; expect "No changes were needed"

## Docs and release

- [ ] README matches the step list from `./bootstrap.sh --list`
- [ ] `SECURITY.md` still lists what this does **not** secure
- [ ] `CHANGELOG.md` has a dated `[0.1.0]` (or newer) section
- [ ] GitHub Pages `docs/` checklist matches the steps
- [ ] Release notes point at the changelog and the Pages checklist
