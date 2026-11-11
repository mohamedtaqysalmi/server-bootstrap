# Test report

## CI

Tracked in GitHub Actions on each pull request: shellcheck, shfmt, CLI test, container step test.

## Local / container (this workspace)

Commands:

```bash
bash tests/test_cli.sh
docker run --rm -e BOOTSTRAP_TEST_IN_CONTAINER=1 -v "$PWD":/src:ro -w /src \
  ubuntu:24.04 bash tests/test_steps.sh
```

Results will be filled after the container run in this session:

| Suite | Result | Notes |
| --- | --- | --- |
| test_cli.sh | pass | Inside `ubuntu:24.04` |
| test_steps.sh (ubuntu:24.04) | pass | SSH live apply skipped; dry-run + refuse paths covered |
| shellcheck | pass | After fixing `answer` typo in `90-ssh.sh` |
| shfmt | pending | Not installed locally; CI enforces on PR |

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
