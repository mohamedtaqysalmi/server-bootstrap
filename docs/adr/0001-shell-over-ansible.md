# ADR 0001: Plain shell instead of Ansible

- Status: Accepted
- Date: 2026-11-11
- Owner: Mohamed-Taqy Salmi

## Context

`server-bootstrap` hardens a fresh Ubuntu VPS. The common alternatives are a
configuration-management tool (Ansible, Puppet, Salt) or a single script the
operator can read end to end.

## Decision

Ship one dependency-free bash entrypoint (`bootstrap.sh`) plus small step
files. No Ansible, no Python runtime, no extra packages on the target beyond
what each step intentionally installs.

## Why shell wins here

1. Auditability. A reader can open the repo and follow every command that will
   touch SSH, UFW, or sudoers without learning a DSL.
2. Zero bootstrap dependency. A brand-new VPS already has bash. Asking it to
   install Ansible (or pull a collection) before it is hardened is the wrong
   order of operations.
3. Idempotency is still required. Steps use explicit "already done" checks and
   a shared `--dry-run` helper instead of a tool's state engine.
4. Failure surface stays small. Fewer moving parts means fewer ways a half-
   applied run leaves SSH unreachable.

## Consequences

- Pros: easy to review in a PR; works over a single SSH session; dry-run is
  literal ("would run X").
- Cons: no inventory multi-host orchestration; no built-in rolling updates;
  complex branching stays awkward. That is acceptable for a single-VPS
  bootstrap aimed at portfolio clarity and personal servers.
- Non-goal: replacing Ansible for fleets. If you manage many hosts, keep
  Ansible (or similar) and treat this script as a reference checklist.

## Alternatives considered

- Ansible playbook from day one: rejected for the cold-start dependency and
  higher reading cost for a one-host bootstrap.
- Cloud-init only: rejected because re-runs and dry-runs are weaker once the
  instance already exists.
