# shellcheck shell=bash
# shellcheck disable=SC2034  # globals shared with bootstrap.sh and the steps
# Logging and the change counter. Sourced by bootstrap.sh.

DRY_RUN="${DRY_RUN:-0}"
CHANGES=0
CURRENT_STEP=""

log_step() { printf '==> %s\n' "$*"; }
log_ok() { printf '  ok      %s\n' "$*"; }
log_warn() { printf '  warn    %s\n' "$*" >&2; }
log_error() { printf 'error: %s\n' "$*" >&2; }

# Record that something is (or, in dry-run, would be) changed on the machine.
# The final summary is built from this counter, which is what lets a second
# run say "No changes".
log_change() {
  CHANGES=$((CHANGES + 1))
  if [ "${DRY_RUN}" -eq 1 ]; then
    printf '  would   %s\n' "$*"
  else
    printf '  change  %s\n' "$*"
  fi
}

die() {
  log_error "$*"
  exit 1
}
