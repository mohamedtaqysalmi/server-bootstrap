# shellcheck shell=bash
# Step: ssh
# Protects against: password guessing and root login over SSH.
# Re-run: does nothing if sshd already matches the hardened settings.
# Dry-run: prints the warning and the config it would write; changes nothing.
#
# MUST run last. Disabling password auth or root login before the non-root
# user has a working key is how people lock themselves out. The step refuses
# to apply those settings unless a key exists for BOOTSTRAP_USER, prints a
# loud warning, and requires BOOTSTRAP_CONFIRM_SSH=1 on non-interactive runs.

SSH_PORT="${SSH_PORT:-22}"
BOOTSTRAP_CONFIRM_SSH="${BOOTSTRAP_CONFIRM_SSH:-0}"

SSHD_DROPIN=/etc/ssh/sshd_config.d/99-server-bootstrap.conf

step_ssh() {
  local desired current_port out answer backup

  _ssh_warn_lockout

  if ! user_has_authorized_keys "${BOOTSTRAP_USER}"; then
    if [ "${DRY_RUN}" -eq 1 ]; then
      log_warn "dry-run: ${BOOTSTRAP_USER} has no authorized_keys yet; a real run would refuse SSH hardening"
    else
      die "refusing to harden SSH: ${BOOTSTRAP_USER} has no authorized_keys. Fix the user step first, or you will lock yourself out"
    fi
  fi

  if [ "${DRY_RUN}" -eq 0 ] && [ "${BOOTSTRAP_CONFIRM_SSH}" != "1" ]; then
    if [ -t 0 ]; then
      printf 'Type YES to apply SSH hardening: ' >&2
      read -r answer
      [ "${answer}" = "YES" ] || die "SSH hardening aborted (expected YES)"
    else
      die "SSH hardening needs BOOTSTRAP_CONFIRM_SSH=1 when stdin is not a terminal"
    fi
  fi

  desired="# Managed by server-bootstrap.
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
X11Forwarding no
AllowUsers ${BOOTSTRAP_USER}"

  # Open the new port in UFW before sshd starts listening only there.
  if [ "${SSH_PORT}" != "22" ] && command -v ufw >/dev/null 2>&1; then
    if ! in_container || [ "${BOOTSTRAP_FORCE_UFW:-0}" = "1" ]; then
      if ufw status 2>/dev/null | grep -Eq "${SSH_PORT}/tcp.*ALLOW"; then
        log_ok "ufw already allows ${SSH_PORT}/tcp for SSH"
      else
        log_change "ufw allow ${SSH_PORT}/tcp before changing sshd Port"
        run ufw allow "${SSH_PORT}/tcp" comment "OpenSSH-custom"
      fi
    fi
  fi

  ensure_file "${SSHD_DROPIN}" 644 "${desired}"

  if [ "${DRY_RUN}" -eq 1 ]; then
    log_ok "dry-run: would validate with sshd -t and reload ssh"
    return 0
  fi

  if ! command -v sshd >/dev/null 2>&1; then
    pkg_install openssh-server
  fi

  if ! out="$(sshd -t 2>&1)"; then
    log_error "sshd rejected ${SSHD_DROPIN}:"
    printf '%s\n' "${out}" >&2
    backup="$(find "$(dirname "${SSHD_DROPIN}")" -maxdepth 1 -type f -name "$(basename "${SSHD_DROPIN}").bak-*" | sort | tail -n 1)"
    if [ -n "${backup}" ]; then
      run mv "${backup}" "${SSHD_DROPIN}"
    else
      run rm -f "${SSHD_DROPIN}"
    fi
    die "SSH hardening aborted; previous sshd config restored if a backup existed"
  fi

  if have_systemd; then
    if systemctl list-unit-files ssh.service 2>/dev/null | grep -q ssh.service; then
      log_change "reload ssh so the new settings take effect"
      run systemctl reload ssh || run systemctl restart ssh
    elif systemctl list-unit-files sshd.service 2>/dev/null | grep -q sshd.service; then
      log_change "reload sshd so the new settings take effect"
      run systemctl reload sshd || run systemctl restart sshd
    else
      log_warn "no ssh/sshd systemd unit found; config written but not reloaded"
    fi
  fi

  _ssh_verify_effective

  # Keep fail2ban pointing at the real SSH port after a port change.
  if [ -f /etc/fail2ban/jail.d/server-bootstrap.local ]; then
    ensure_file /etc/fail2ban/jail.d/server-bootstrap.local 644 \
      "# Managed by server-bootstrap.
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ${SSH_PORT}
backend = systemd"
    if [ "${FILE_CHANGED}" -eq 1 ]; then
      fail2ban-client -t >/dev/null || die "fail2ban rejected the updated jail after SSH port change"
      service_restart_if_running fail2ban
    fi
  fi

  current_port="$(sshd -T 2>/dev/null | awk '/^port /{print $2; exit}' || true)"
  log_ok "sshd is listening with hardened settings (port ${current_port:-unknown})"
  log_warn "keep this session open. Open a second session as ${BOOTSTRAP_USER} before you disconnect"
}

_ssh_warn_lockout() {
  log_warn "=============================================================="
  log_warn "SSH HARDENING CAN LOCK YOU OUT OF THIS SERVER"
  log_warn "Before this step continues, confirm all of the following:"
  log_warn "  1. You can log in as ${BOOTSTRAP_USER} with an SSH key"
  log_warn "  2. UFW (or your cloud firewall) allows TCP port ${SSH_PORT}"
  log_warn "  3. You have a second terminal ready to test a new session"
  log_warn "  4. Provider console / VNC recovery is available if something fails"
  log_warn "Set BOOTSTRAP_CONFIRM_SSH=1 for non-interactive runs."
  log_warn "=============================================================="
}

_ssh_verify_effective() {
  local effective
  effective="$(sshd -T 2>/dev/null || true)"
  [ -n "${effective}" ] || die "sshd -T produced no output; cannot verify hardening"

  echo "${effective}" | grep -qiE '^permitrootlogin no$' ||
    die "verification failed: PermitRootLogin is not 'no'"
  echo "${effective}" | grep -qiE '^passwordauthentication no$' ||
    die "verification failed: PasswordAuthentication is not 'no'"
  echo "${effective}" | grep -qiE '^pubkeyauthentication yes$' ||
    die "verification failed: PubkeyAuthentication is not 'yes'"
  if [ "${SSH_PORT}" != "22" ]; then
    echo "${effective}" | grep -qiE "^port ${SSH_PORT}$" ||
      die "verification failed: sshd port is not ${SSH_PORT}"
  fi
  log_ok "sshd -T confirms PermitRootLogin=no PasswordAuthentication=no PubkeyAuthentication=yes"
}
