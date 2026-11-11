# shellcheck shell=bash
# shellcheck disable=SC2034  # globals shared with bootstrap.sh and the steps
# Idempotent file helpers. Both set FILE_CHANGED to 1 when they changed (or, in
# dry-run, would change) the file, so a step can restart a service only when
# its configuration actually moved.

FILE_CHANGED=0

# Copy an existing file to <file>.bak-<timestamp> before it is modified.
backup_file() {
  local path="$1" stamp
  [ -e "${path}" ] || return 0
  stamp="$(date +%Y%m%d%H%M%S)"
  run cp -p -- "${path}" "${path}.bak-${stamp}"
}

# ensure_line <file> <line>
# Appends the line unless the file already contains exactly that line.
ensure_line() {
  local file="$1" line="$2"
  FILE_CHANGED=0
  if [ -f "${file}" ] && grep -qxF -- "${line}" "${file}"; then
    log_ok "${file} already has: ${line}"
    return 0
  fi
  FILE_CHANGED=1
  log_change "add to ${file}: ${line}"
  backup_file "${file}"
  if [ "${DRY_RUN}" -eq 1 ]; then
    return 0
  fi
  # Do not glue the new line onto an unterminated last line.
  if [ -s "${file}" ] && [ -n "$(tail -c 1 "${file}")" ]; then
    printf '\n' >>"${file}"
  fi
  printf '%s\n' "${line}" >>"${file}"
}

# ensure_file <path> <mode> <content>
# Makes the file hold exactly <content> (plus a trailing newline) with <mode>.
# An existing file with different content is backed up first.
ensure_file() {
  local path="$1" mode="$2" content="$3" tmp
  FILE_CHANGED=0
  if [ -f "${path}" ] && printf '%s\n' "${content}" | cmp -s - "${path}"; then
    if [ "$(stat -c %a "${path}")" = "${mode}" ]; then
      log_ok "${path} is up to date"
      return 0
    fi
    FILE_CHANGED=1
    log_change "chmod ${mode} ${path}"
    run chmod "${mode}" "${path}"
    return 0
  fi
  FILE_CHANGED=1
  log_change "write ${path}"
  backup_file "${path}"
  if [ "${DRY_RUN}" -eq 1 ]; then
    return 0
  fi
  mkdir -p -- "$(dirname "${path}")"
  # Write next to the target and rename, so a crash never leaves half a file.
  tmp="$(mktemp "${path}.XXXXXX")"
  printf '%s\n' "${content}" >"${tmp}"
  chmod "${mode}" "${tmp}"
  mv -- "${tmp}" "${path}"
}
