# ADR 0003: Caddy default, Nginx optional

- Status: Accepted
- Date: 2026-11-11

## Context

The reverse proxy needs automatic HTTPS on a single VPS. Nginx + certbot is familiar; Caddy obtains and renews certificates from a short Caddyfile.

## Decision

Default `BOOTSTRAP_PROXY=caddy`. Operators can set `BOOTSTRAP_PROXY=nginx` (certbot when a domain is set) or `none`. If `BOOTSTRAP_DOMAIN` is empty, write an HTTP `:80` placeholder so a later re-run enables TLS without reinstalling.

## Consequences

- Default path stays short enough to audit.
- Nginx remains available for teams that already standardize on it.
