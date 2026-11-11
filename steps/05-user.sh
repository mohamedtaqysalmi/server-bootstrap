# shellcheck shell=bash
# Step: use
# Protects against: day-to-day work as root, so a mistake or compromised session has the full machine.
# Re-run: does nothing if the user, sudo membership and authorized_keys are already in place.
# Dry-run: prints the useradd / usermod / key install it would do.
#
# Set BOOTSTRAP_USER (default deploy), optional BOOTSTRAP_SSH_PUBKEY o
# BOOTSTRAP_SSH_PUBKEY_FILE. When neither is set, keys are copied from root if
# present. BOOTSTRAP_SUDO_NOPASSWD=1 (default) writes a sudoers drop-in.

step_user() {
  ensure_login_user "${BOOTSTRAP_USER}"
}
