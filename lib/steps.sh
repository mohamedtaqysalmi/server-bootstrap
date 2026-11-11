# shellcheck shell=bash
# shellcheck disable=SC2034  # globals shared with bootstrap.sh and the steps
# Step discovery and selection. A step is steps/NN-name.sh defining a function
# step_name (dashes in the name become underscores). Files run in name order.

STEPS_DIR="${BOOTSTRAP_DIR}/steps"
ONLY=""
SKIP=""

step_files() {
  local f
  for f in "${STEPS_DIR}"/*.sh; do
    [ -e "${f}" ] && printf '%s\n' "${f}"
  done
  return 0
}

step_name() {
  local base
  base="$(basename "$1" .sh)"
  printf '%s' "${base#[0-9][0-9]-}"
}

csv_contains() {
  [[ ",$1," == *",$2,"* ]]
}

# validate_step_list <option-name> <comma separated names>
validate_step_list() {
  local option="$1" list="$2" name f known
  local names=()
  IFS=',' read -r -a names <<<"${list}"
  for name in "${names[@]}"; do
    known=0
    while IFS= read -r f; do
      if [ "$(step_name "${f}")" = "${name}" ]; then
        known=1
      fi
    done < <(step_files)
    if [ "${known}" -eq 0 ]; then
      log_error "${option}: unknown step '${name}'. Run ./bootstrap.sh --list to see the steps"
      return 1
    fi
  done
}

list_steps() {
  local f
  while IFS= read -r f; do
    printf '%-22s %s\n' "$(step_name "${f}")" "$(sed -n 's/^# Protects against: //p' "${f}")"
  done < <(step_files)
}

run_steps() {
  local f name fn
  while IFS= read -r f; do
    name="$(step_name "${f}")"
    if [ -n "${ONLY}" ] && ! csv_contains "${ONLY}" "${name}"; then
      continue
    fi
    if csv_contains "${SKIP}" "${name}"; then
      log_step "${name} (skipped by --skip)"
      continue
    fi
    CURRENT_STEP="${name}"
    log_step "${name}"
    # shellcheck source=/dev/null
    . "${f}"
    fn="step_${name//-/_}"
    if ! declare -F "${fn}" >/dev/null; then
      die "${f} does not define ${fn}"
    fi
    "${fn}"
    CURRENT_STEP=""
  done < <(step_files)
}
