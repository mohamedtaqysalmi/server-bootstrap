# shellcheck shell=bash
# Step: ufw
# Protects against: unexpected inbound services being reachable from the internet.
# Re-run: does nothing if the default policy, allows and enabled state already match.
# Dry-run: prints the ufw commands it would run.
#
# Containers do not own the host firewall, so this step skips itself there unless
# BOOTSTRAP_FORCE_UFW=1. SSH is allowed before the firewall is enabled so a
# mistake here is less likely to lock you out; the ssh step still runs last.

SSH_PORT="${SSH_PORT:-22}"

step_ufw() {
  if in_container && [ "${BOOTSTRAP_FORCE_UFW:-0}" != "1" ]; then
    log_ok "running in a container, host firewall is out of scope, skipping"
    return 0
  fi

  pkg_install ufw

  # Policy and rules are checked by reading ufw's status. Exact rule text varies
  # slightly by Ubuntu version, so we look for the port / profile names.
  local status
  status="$(ufw status verbose 2>/dev/null || true)"

  if grep -q '^Default: deny (incoming), allow (outgoing)' <<<"${status}"; then
    log_ok "ufw default policy is deny incoming / allow outgoing"
  else
    log_change "set ufw defaults: deny incoming, allow outgoing"
    run ufw default deny incoming
    run ufw default allow outgoing
  fi

  if ufw status 2>/dev/null | grep -Eq "(OpenSSH|${SSH_PORT}/tcp).*ALLOW"; then
    log_ok "ufw allows SSH on port ${SSH_PORT}"
  else
    log_change "allow SSH on port ${SSH_PORT}/tcp through ufw"
    if [ "${SSH_PORT}" = "22" ]; then
      run ufw allow OpenSSH
    else
      run ufw allow "${SSH_PORT}/tcp"
    fi
  fi

  if ufw status 2>/dev/null | grep -Eq '80/tcp.*ALLOW'; then
    log_ok "ufw allows HTTP (80/tcp)"
  else
    log_change "allow HTTP (80/tcp) through ufw"
    run ufw allow 80/tcp
  fi

  if ufw status 2>/dev/null | grep -Eq '443/tcp.*ALLOW'; then
    log_ok "ufw allows HTTPS (443/tcp)"
  else
    log_change "allow HTTPS (443/tcp) through ufw"
    run ufw allow 443/tcp
  fi

  if ufw status 2>/dev/null | grep -q '^Status: active'; then
    log_ok "ufw is active"
  else
    log_change "enable ufw (non-interactive)"
    run ufw --force enable
  fi
}
