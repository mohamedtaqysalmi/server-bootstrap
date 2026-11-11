# shellcheck shell=bash
# Checks about the machine we run on, and package and service helpers.

# Tests point this at a fake file to exercise the unsupported-OS path.
OS_RELEASE_FILE="${OS_RELEASE_FILE:-/etc/os-release}"
SUPPORTED_UBUNTU_VERSIONS="22.04 24.04"
APT_UPDATED=0

os_field() {
  sed -n "s/^$1=//p" "${OS_RELEASE_FILE}" | head -n 1 | tr -d '"'
}

check_os() {
  local id version
  [ -r "${OS_RELEASE_FILE}" ] || die "cannot read ${OS_RELEASE_FILE}, cannot tell which OS this is"
  id="$(os_field ID)"
  version="$(os_field VERSION_ID)"
  if [ "${id}" != "ubuntu" ]; then
    die "unsupported OS '${id:-unknown}'. This script supports Ubuntu ${SUPPORTED_UBUNTU_VERSIONS// /, } only"
  fi
  case " ${SUPPORTED_UBUNTU_VERSIONS} " in
  *" ${version} "*) log_ok "Ubuntu ${version}" ;;
  *) die "unsupported Ubuntu version '${version}'. Supported: ${SUPPORTED_UBUNTU_VERSIONS// /, }" ;;
  esac
}

# Real runs change system files, so they need root. A dry run only reads.
check_root() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    return 0
  fi
  if [ "$(id -u)" -ne 0 ]; then
    die "must run as root (for example: sudo ./bootstrap.sh). Use --dry-run to preview without root"
  fi
}

in_container() {
  [ -f /.dockerenv ] || [ -f /run/.containerenv ] || systemd-detect-virt --container --quiet 2>/dev/null
}

have_systemd() {
  [ -d /run/systemd/system ]
}

# pkg_install <package>...
# Installs only the packages that are missing; runs apt-get update only then.
pkg_install() {
  local pkg
  local missing=()
  for pkg in "$@"; do
    # shellcheck disable=SC2016  # ${Status} is a dpkg-query format, not a shell variable
    if dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q '^install ok installed$'; then
      log_ok "package ${pkg} is installed"
    else
      missing+=("${pkg}")
    fi
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    return 0
  fi
  log_change "install packages: ${missing[*]}"
  if [ "${APT_UPDATED}" -eq 0 ]; then
    run apt-get update -q
    APT_UPDATED=1
  fi
  run env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y -q "${missing[@]}"
}

# service_enable_now <unit>
service_enable_now() {
  local unit="$1"
  if ! have_systemd; then
    log_warn "systemd is not running, not enabling ${unit}"
    return 0
  fi
  if systemctl is-enabled --quiet "${unit}" 2>/dev/null && systemctl is-active --quiet "${unit}" 2>/dev/null; then
    log_ok "${unit} is enabled and running"
    return 0
  fi
  log_change "enable and start ${unit}"
  run systemctl enable --now "${unit}"
}

# service_restart_if_running <unit>
# Used after a config file changed. A unit that is not running picks the new
# config up when service_enable_now starts it.
service_restart_if_running() {
  local unit="$1"
  if have_systemd && systemctl is-active --quiet "${unit}" 2>/dev/null; then
    log_change "restart ${unit} to load the new configuration"
    run systemctl restart "${unit}"
  fi
}
