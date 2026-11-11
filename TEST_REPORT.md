# Test report

## CI

Tracked in GitHub Actions on each pull request: shellcheck, shfmt, CLI test, container step test.

## Local / container run

Last run: 2026-11-11, Docker 29.9.2 on Windows 11, image `ubuntu:24.04`. The same two suites run in CI on every pull request.

```bash
bash tests/test_cli.sh
docker run --rm -e BOOTSTRAP_TEST_IN_CONTAINER=1 -v "$PWD":/src:ro -w /src   ubuntu:24.04 bash tests/test_steps.sh
```

| Suite | Checks | Result | Notes |
| --- | --- | --- | --- |
| test_cli.sh | 7 | 7 pass | Flags, `--list` order, unknown step and flag handling |
| test_steps.sh on `ubuntu:24.04` | 42 | 42 pass | Dry run changes nothing; second real run reports no changes |
| test_steps.sh on `ubuntu:22.04` | 42 | 7 fail | `caddy` is not in the 22.04 archive, so the proxy step stops. 22.04 is refused by the script until that is fixed |
| shellcheck | all `*.sh` | pass | CI |
| shfmt | all `*.sh` | pass | CI, pinned version with checksum |

Two bugs were found while preparing this report: the SSH step asked apt for `openssh-serve`, and one swap check assumed the container never sees an active `/swapfile` (GitHub's runners expose theirs). Both are fixed.

## Coverage

Bash project: no line-coverage tool in CI. Behaviour coverage is the container idempotency test (first run changes, second run no changes) plus CLI checks.

## Lighthouse (Pages)

Measure after Pages deploy. Target 90+ on performance, accessibility, best practices, SEO.

| Category | Score | Date |
| --- | --- | --- |
| Performance | pending | |
| Accessibility | pending | |
| Best practices | pending | |
| SEO | pending | |

## Not tested in CI

- Live `ufw --force enable` on a real NIC
- Live `sshd` reload and second-session login
- Let's Encrypt issuance (needs a public DNS name)
- Swap file creation (containers skip swap)
