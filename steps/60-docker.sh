# shellcheck shell=bash
# Step: docke
# Protects against: running workloads without isolation, and unbounded container logs filling the disk.
# Re-run: does nothing if docker is installed, the daemon log limits exist, and the user is in the docker group.
# Dry-run: prints the package install and file writes it would do.
#
# Uses Ubuntu's docker.io package so the install stays auditable without a third-party apt source.
# The daemon is not started inside plain containers (no systemd).

step_docker() {
  local daemon_changed=0

  pkg_install docker.io docker-compose-v2

  ensure_file /etc/docker/daemon.json 644 \
    '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}'
  daemon_changed="${FILE_CHANGED}"

  if user_exists "${BOOTSTRAP_USER}"; then
    if id -nG "${BOOTSTRAP_USER}" | tr ' ' '\n' | grep -qx docker; then
      log_ok "${BOOTSTRAP_USER} is in the docker group"
    else
      log_change "add ${BOOTSTRAP_USER} to the docker group"
      run usermod -aG docker "${BOOTSTRAP_USER}"
    fi
  else
    log_warn "user ${BOOTSTRAP_USER} does not exist yet; run the user step so it can be added to the docker group"
  fi

  if [ "${daemon_changed}" -eq 1 ]; then
    service_restart_if_running docke
  fi
  service_enable_now docke
}
