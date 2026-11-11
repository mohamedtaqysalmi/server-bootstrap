# shellcheck shell=bash
# Step: monitoring
# Protects against: not noticing CPU, memory or disk pressure until the site is already down.
# Re-run: does nothing if the exporter package and unit are already in place.
# Dry-run: prints what it would install.
#
# Optional. Skipped unless ENABLE_MONITORING=1. Installs Ubuntu's
# prometheus-node-exporter and leaves it on localhost defaults — it does not
# open a firewall port, so scraping from another host needs an explicit allow.

ENABLE_MONITORING="${ENABLE_MONITORING:-0}"

step_monitoring() {
  if [ "${ENABLE_MONITORING}" != "1" ]; then
    log_ok "ENABLE_MONITORING is not 1, skipping optional monitoring"
    return 0
  fi

  pkg_install prometheus-node-exporter
  service_enable_now prometheus-node-exporter
  log_ok "node exporter listens on localhost by default; open ufw only if an external Prometheus must scrape it"
}
