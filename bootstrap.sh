#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="0.1.0"
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/log.sh
. "${BOOTSTRAP_DIR}/lib/log.sh"
# shellcheck source=lib/run.sh
. "${BOOTSTRAP_DIR}/lib/run.sh"
# shellcheck source=lib/files.sh
. "${BOOTSTRAP_DIR}/lib/files.sh"
# shellcheck source=lib/system.sh
. "${BOOTSTRAP_DIR}/lib/system.sh"
# shellcheck source=lib/users.sh
. "${BOOTSTRAP_DIR}/lib/users.sh"
# shellcheck source=lib/steps.sh
. "${BOOTSTRAP_DIR}/lib/steps.sh"

trap 'log_error "failed${CURRENT_STEP:+ in step ${CURRENT_STEP}} (line ${LINENO})"' ERR

usage() {
  cat <<USAGE
Usage: bootstrap.sh [options]

Setup for a fresh Ubuntu VPS (22.04 or 24.04). Safe to run again: steps that
are already done report "ok" and change nothing.

SSH hardening runs last. It can lock you out. Read the warning it prints, keep
your current session open, and open a second session before you disconnect.

Options:
  --dry-run        Print what would change without changing anything.
  --only a,b       Run only these steps.
  --skip a,b       Run all steps except these.
  --list           List the steps and what each one protects against.
  --help           Show this help and exit.
  --version        Show the version and exit.

Environment:
  BOOTSTRAP_USER            Non-root sudo account (default: deploy).
  BOOTSTRAP_SSH_PUBKEY      Public key line installed for that account.
  BOOTSTRAP_SSH_PUBKEY_FILE Path to a public key / authorized_keys file.
  BOOTSTRAP_SUDO_NOPASSWD   1 (default) writes a passwordless sudoers drop-in.
  BOOTSTRAP_CONFIRM_SSH     Set to 1 to apply SSH hardening non-interactively.
  SSH_PORT                  sshd port (default: 22). Changed last, after UFW.
  SWAP_SIZE                 Size of the swap file (default 2G).
  SWAP_FILE                 Path of the swap file (default /swapfile).
  BOOTSTRAP_PROXY           Reverse proxy: caddy (default), nginx, or none.
  BOOTSTRAP_DOMAIN          Domain for automatic HTTPS (empty = :80 placeholder).
  BOOTSTRAP_ACME_EMAIL      ACME account email (optional; used by Caddy/certbot).
  BOOTSTRAP_PROXY_UPSTREAM  Reverse-proxy target (default 127.0.0.1:8080).
  ENABLE_MONITORING         Set to 1 to install prometheus-node-exporter.
USAGE
}

usage_error() {
  log_error "$1"
  usage >&2
  exit 2
}

want_list=0

while [ "$#" -gt 0 ]; do
  case "$1" in
  --help | -h)
    usage
    exit 0
    ;;
  --version)
    echo "server-bootstrap ${VERSION}"
    exit 0
    ;;
  --dry-run)
    DRY_RUN=1
    ;;
  --list)
    want_list=1
    ;;
  --only | --skip)
    [ "$#" -ge 2 ] || usage_error "$1 needs a value"
    if [ "$1" = "--only" ]; then ONLY="$2"; else SKIP="$2"; fi
    shift
    ;;
  --only=*) ONLY="${1#--only=}" ;;
  --skip=*) SKIP="${1#--skip=}" ;;
  *) usage_error "unknown option: $1" ;;
  esac
  shift
done

if [ -n "${ONLY}" ]; then validate_step_list --only "${ONLY}" || exit 2; fi
if [ -n "${SKIP}" ]; then validate_step_list --skip "${SKIP}" || exit 2; fi

if [ "${want_list}" -eq 1 ]; then
  list_steps
  exit 0
fi

if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Dry run: nothing will be changed."
fi

check_os
check_root
run_steps

echo
if [ "${DRY_RUN}" -eq 1 ]; then
  if [ "${CHANGES}" -eq 0 ]; then
    echo "Dry run finished. No changes would be made."
  else
    echo "Dry run finished. ${CHANGES} change(s) would be made."
  fi
elif [ "${CHANGES}" -eq 0 ]; then
  echo "Done. No changes were needed."
else
  echo "Done. ${CHANGES} change(s) made."
fi
