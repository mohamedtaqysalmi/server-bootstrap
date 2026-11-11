#!/usr/bin/env bash
# Plain-bash checks for the command line interface of bootstrap.sh.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT}/bootstrap.sh"
failures=0

# Working trees edited on Windows can carry CRLF; strip for this process only.
if grep -q $'\r' "${SCRIPT}" 2>/dev/null; then
  TMP="$(mktemp)"
  tr -d '\r' <"${SCRIPT}" >"${TMP}"
  SCRIPT="${TMP}"
fi

pass() { echo "ok   - $1"; }
fail() {
  echo "FAIL - $1"
  failures=$((failures + 1))
}

# check_exit <description> <expected status> <expected text or empty> <args...>
check() {
  local desc="$1" want_status="$2" want_text="$3"
  shift 3
  local out status
  out="$(bash "${SCRIPT}" "$@" 2>&1)"
  status=$?
  if [ "${want_status}" = "nonzero" ]; then
    [ "${status}" -ne 0 ] || {
      fail "${desc} (exit was 0)"
      return
    }
  else
    [ "${status}" -eq "${want_status}" ] || {
      fail "${desc} (exit ${status})"
      return
    }
  fi
  if [ -n "${want_text}" ] && [[ "${out}" != *"${want_text}"* ]]; then
    fail "${desc} (output missing '${want_text}')"
    return
  fi
  pass "${desc}"
}

check "--help exits 0 and prints usage" 0 "Usage: bootstrap.sh" --help
check "--version exits 0 and prints version" 0 "server-bootstrap 0.1.0" --version
check "--list exits 0 and names the steps" 0 "fail2ban" --list
check "--list includes ssh last among named steps" 0 "ssh" --list
check "--only with an unknown step exits 2" 2 "unknown step" --only nope
check "--skip with an unknown step exits 2" 2 "unknown step" --skip nope
check "unknown flag exits non-zero" nonzero "unknown option" --bogus

if [ "${failures}" -ne 0 ]; then
  echo "${failures} check(s) failed"
  exit 1
fi
echo "all checks passed"
