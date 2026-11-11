# shellcheck shell=bash
# The only place a step should execute a command that changes the system.

# run <command> [args...]
# Under --dry-run it prints the command instead of executing it.
run() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    printf '  [dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}
