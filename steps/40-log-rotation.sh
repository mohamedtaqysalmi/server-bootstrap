# shellcheck shell=bash
# Step: log-rotation
# Protects against: logs filling the disk until the server stops working.
# Re-run: does nothing if logrotate is installed and the journald limits are in place.
# Dry-run: prints what it would install and write.
#
# Covers the system journal (capped here) and /var/log files (logrotate, which
# Ubuntu packages already configure). Docker container logs get their own
# limit in the Docker step, once that exists.

step_log_rotation() {
  pkg_install logrotate

  ensure_file /etc/systemd/journald.conf.d/50-server-bootstrap.conf 644 \
    '# Managed by server-bootstrap.
[Journal]
SystemMaxUse=500M
MaxRetentionSec=1month'

  if [ "${FILE_CHANGED}" -eq 1 ]; then
    service_restart_if_running systemd-journald
  fi

  if [ "${DRY_RUN}" -eq 0 ]; then
    logrotate --debug /etc/logrotate.conf >/dev/null 2>&1 ||
      die "logrotate rejects /etc/logrotate.conf. Run 'logrotate --debug /etc/logrotate.conf' to see why"
  fi
}
