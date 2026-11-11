# Security policy

This script changes SSH, firewall, sudo and package settings on servers, so
security reports matter.

## Reporting a vulnerability

Please do not open a public issue. Use the "Report a vulnerability" button on
the
[Security tab](https://github.com/mohamedtaqysalmi/server-bootstrap/security/advisories/new)
of this repository. That opens a private report that only I can see.

This is a solo-maintained project. I aim to reply within a few days, but I
cannot promise a fixed response time.

## Supported versions

| Version | Supported |
| ------- | --------- |
| 0.1.x   | Yes       |
| < 0.1   | No        |

## What this does NOT secure

`server-bootstrap` is a starting point for a single Ubuntu VPS. It is not a
complete security program. In particular it does **not**:

- Replace your cloud provider's perimeter firewall, security groups, or DDoS
  controls. UFW only filters on the host.
- Protect against zero-days, supply-chain compromise of apt packages, or a
  malicious ISO/image you already booted.
- Configure intrusion detection, EDR, auditd rulesets, SELinux/AppArmor
  policy authoring, or host-based integrity monitoring beyond what Ubuntu
  ships by default.
- Manage secrets, vaults, SSH certificate authorities, or hardware keys.
- Guarantee you cannot lock yourself out. The SSH step can disable password
  and root login; you must verify key login in a second session first.
- Tune application security (OWASP, headers, WAF, database auth, container
  image scanning). Docker and the reverse proxy only prepare a runtime path.
- Open or secure monitoring scrape ports. Optional node exporter stays on
  localhost defaults until you deliberately expose it.
- Handle multi-tenant isolation, PCI/HIPAA/SOC2 evidence, or continuous
  compliance.
- Update itself. Re-run after you pull a new release; there is no phone-home
  updater.
- Recover a broken server. Keep provider console/VNC access available.

If you need those controls, add them explicitly on top of this baseline.
