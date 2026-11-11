# shellcheck shell=bash
# Step: unattended-upgrades
# Protects against: known vulnerabilities staying unpatched because nobody logged in to run apt upgrade.
# Re-run: does nothing if the package and both config files are already in place.
# Dry-run: prints what it would install and write.
#
# Automatic reboot is off on purpose: a kernel update only takes effect after
# a reboot, and rebooting a server unannounced is the owner's decision.

step_unattended_upgrades() {
  pkg_install unattended-upgrades

  ensure_file /etc/apt/apt.conf.d/20auto-upgrades 644 \
    'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";'

  ensure_file /etc/apt/apt.conf.d/52server-bootstrap-unattended-upgrades 644 \
    '// Managed by server-bootstrap.
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";'

  service_enable_now apt-daily.timer
  service_enable_now apt-daily-upgrade.timer

  if [ "${DRY_RUN}" -eq 0 ]; then
    # Prefer reading the file we manage. apt-config dump can lag or differ in
    # minimal containers right after the first package install.
    grep -q 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades ||
      die "20auto-upgrades does not enable Unattended-Upgrade after writing it"
  fi
}
