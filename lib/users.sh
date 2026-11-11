# shellcheck shell=bash
# Create a login user, give it sudo, and make sure it has an SSH public key.

BOOTSTRAP_USER="${BOOTSTRAP_USER:-deploy}"
BOOTSTRAP_SUDO_NOPASSWD="${BOOTSTRAP_SUDO_NOPASSWD:-1}"
BOOTSTRAP_SSH_PUBKEY="${BOOTSTRAP_SSH_PUBKEY:-}"
BOOTSTRAP_SSH_PUBKEY_FILE="${BOOTSTRAP_SSH_PUBKEY_FILE:-}"

user_exists() {
  id -u "$1" >/dev/null 2>&1
}

user_home() {
  local home
  home="$(getent passwd "$1" | cut -d: -f6)" || return 1
  [ -n "${home}" ] || return 1
  printf '%s\n' "${home}"
}

# Sets RESOLVED_SSH_PUBKEY_KIND to env|file and RESOLVED_SSH_PUBKEY_VALUE to the
# key text or file path. Returns 1 when nothing is available.
resolve_ssh_pubkey() {
  RESOLVED_SSH_PUBKEY_KIND=""
  RESOLVED_SSH_PUBKEY_VALUE=""
  if [ -n "${BOOTSTRAP_SSH_PUBKEY}" ]; then
    RESOLVED_SSH_PUBKEY_KIND="env"
    RESOLVED_SSH_PUBKEY_VALUE="${BOOTSTRAP_SSH_PUBKEY}"
    return 0
  fi
  if [ -n "${BOOTSTRAP_SSH_PUBKEY_FILE}" ]; then
    [ -r "${BOOTSTRAP_SSH_PUBKEY_FILE}" ] || die "BOOTSTRAP_SSH_PUBKEY_FILE=${BOOTSTRAP_SSH_PUBKEY_FILE} is not readable"
    RESOLVED_SSH_PUBKEY_KIND="file"
    RESOLVED_SSH_PUBKEY_VALUE="${BOOTSTRAP_SSH_PUBKEY_FILE}"
    return 0
  fi
  if [ -s /root/.ssh/authorized_keys ]; then
    RESOLVED_SSH_PUBKEY_KIND="file"
    RESOLVED_SSH_PUBKEY_VALUE="/root/.ssh/authorized_keys"
    return 0
  fi
  return 1
}

write_authorized_keys() {
  local user="$1" home auth_dir auth_file

  if [ "${RESOLVED_SSH_PUBKEY_KIND}" = "env" ]; then
    log_change "install SSH authorized_keys for ${user} from BOOTSTRAP_SSH_PUBKEY"
  else
    log_change "install SSH authorized_keys for ${user} from ${RESOLVED_SSH_PUBKEY_VALUE}"
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    return 0
  fi

  home="$(user_home "${user}")"
  [ -n "${home}" ] || die "cannot resolve home directory for ${user}"
  auth_dir="${home}/.ssh"
  auth_file="${auth_dir}/authorized_keys"

  mkdir -p -- "${auth_dir}"
  chmod 700 "${auth_dir}"
  if [ "${RESOLVED_SSH_PUBKEY_KIND}" = "env" ]; then
    printf '%s\n' "${RESOLVED_SSH_PUBKEY_VALUE}" >"${auth_file}"
  else
    cp -- "${RESOLVED_SSH_PUBKEY_VALUE}" "${auth_file}"
  fi
  chmod 600 "${auth_file}"
  chown -R "${user}:${user}" "${auth_dir}"
}

ensure_sudo_membership() {
  local user="$1"
  local drop_in="/etc/sudoers.d/90-server-bootstrap-${user}"

  if user_exists "${user}"; then
    if id -nG "${user}" | tr ' ' '\n' | grep -qx sudo; then
      log_ok "${user} is in the sudo group"
    else
      log_change "add ${user} to the sudo group"
      run usermod -aG sudo "${user}"
    fi
  elif [ "${DRY_RUN}" -eq 1 ]; then
    log_change "add ${user} to the sudo group"
    run usermod -aG sudo "${user}"
  else
    die "cannot configure sudo: user ${user} does not exist"
  fi

  if [ "${BOOTSTRAP_SUDO_NOPASSWD}" = "1" ]; then
    ensure_file "${drop_in}" 440 \
      "# Managed by server-bootstrap.
${user} ALL=(ALL:ALL) NOPASSWD:ALL"
  elif [ -f "${drop_in}" ]; then
    log_change "remove passwordless sudo drop-in ${drop_in}"
    run rm -f -- "${drop_in}"
  else
    log_ok "passwordless sudo is off for ${user}"
  fi
}

# ensure_login_user <name>
# Creates the user if missing, gives sudo, and installs an SSH public key when
# we can find one. Refuses to invent a password.
ensure_login_user() {
  local user="$1" home
  if user_exists "${user}"; then
    log_ok "user ${user} already exists"
  else
    log_change "create user ${user} with home and bash shell"
    run useradd --create-home --shell /bin/bash "${user}"
  fi

  ensure_sudo_membership "${user}"

  if [ "${DRY_RUN}" -eq 1 ] && ! user_exists "${user}"; then
    # Dry-run never created the account, so home lookup would fail.
    if resolve_ssh_pubkey; then
      write_authorized_keys "${user}"
    else
      log_warn "no SSH public key found for ${user}. Set BOOTSTRAP_SSH_PUBKEY or BOOTSTRAP_SSH_PUBKEY_FILE, or install a key on root first."
    fi
    return 0
  fi

  home="$(user_home "${user}")" || die "cannot resolve home directory for ${user}"
  if [ -s "${home}/.ssh/authorized_keys" ]; then
    log_ok "${home}/.ssh/authorized_keys is present"
    return 0
  fi

  if resolve_ssh_pubkey; then
    write_authorized_keys "${user}"
  else
    log_warn "no SSH public key found for ${user}. Set BOOTSTRAP_SSH_PUBKEY or BOOTSTRAP_SSH_PUBKEY_FILE, or install a key on root first. The ssh step will refuse to disable passwords without a key."
  fi
}

user_has_authorized_keys() {
  local user="$1" home
  user_exists "${user}" || return 1
  home="$(user_home "${user}")" || return 1
  [ -s "${home}/.ssh/authorized_keys" ]
}
