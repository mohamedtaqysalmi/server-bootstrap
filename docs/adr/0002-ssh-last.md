# ADR 0002: SSH hardening runs last and is verified

- Status: Accepted
- Date: 2026-11-11

## Context

Turning off password auth or root login while the only working login is root-with-password locks the operator out. Cloud firewall rules and UFW also have to allow the SSH port that will remain.

## Decision

1. Number the SSH step `90-ssh.sh` so it is last.
2. Print a multi-line lockout warning before any write.
3. Refuse to apply if `BOOTSTRAP_USER` has no `authorized_keys`.
4. Require `BOOTSTRAP_CONFIRM_SSH=1` (or an interactive `YES`) on real runs.
5. Write a drop-in under `sshd_config.d`, run `sshd -t`, reload, then verify with `sshd -T`.
6. Open a custom `SSH_PORT` in UFW before sshd switches to it.

## Consequences

- Operators keep their current session open and test a second login.
- Container CI skips the live SSH apply (`--skip ssh`) and still covers the dry-run warning path.
