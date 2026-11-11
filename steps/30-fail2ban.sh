# shellcheck shell=bash
# Step: fail2ban
# Protects against: password-guessing bots hammering SSH, by banning an address after repeated failures.
# Re-run: does nothing if the package, the jail file and the service are already in place.
# Dry-run: prints what it would install and write.
#
# This drop-in assumes sshd listens on the default port. If a later step moves
# SSH to another port, the jail's port setting has to follow.

step_fail2ban() {
  local out

  pkg_install fail2ban

  ensure_file /etc/fail2ban/jail.d/server-bootstrap.local 644 \
    '# Managed by server-bootstrap.
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
# Ubuntu 24.04 has no /var/log/auth.log unless rsyslog is installed, so read the journal.
backend = systemd'

  if [ "${DRY_RUN}" -eq 0 ]; then
    if ! out="$(fail2ban-client -t 2>&1)"; then
      log_error "fail2ban rejected its configuration:"
      printf '%s\n' "${out}" >&2
      return 1
    fi
  fi

  if [ "${FILE_CHANGED}" -eq 1 ]; then
    service_restart_if_running fail2ban
  fi
  service_enable_now fail2ban
}
