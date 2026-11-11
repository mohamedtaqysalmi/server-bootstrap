#!/usr/bin/env bash
# Behaviour tests for the steps. They really install packages and write files
# under /etc, so they only run inside a disposable container:
#
#   docker run --rm -e BOOTSTRAP_TEST_IN_CONTAINER=1 -v "$PWD":/src:ro -w /src \
#     ubuntu:24.04 bash tests/test_steps.sh
#
# Not covered here, because a plain container has no systemd and cannot create
# swap or own the host firewall: starting or restarting services, the swap file
# itself (only its dry-run plan and the container skip), UFW enablement, and a
# live SSH reload. SSH hardening is exercised for refusal / dry-run warning only.
set -uo pipefail

if [ "${BOOTSTRAP_TEST_IN_CONTAINER:-0}" != "1" ] || { [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; }; then
  echo "refusing to run: this test changes the system and must run inside a disposable container" >&2
  echo "see the comment at the top of this file" >&2
  exit 2
fi

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK=/opt/server-bootstrap
OUT=/tmp/test-out
failures=0
TEST_PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyForServerBootstrapCIOnly not-a-real-key'

pass() { echo "ok   - $1"; }
fail() {
  echo "FAIL - $1"
  failures=$((failures + 1))
}

# expect <description> <command...>: passes when the command succeeds.
expect() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then pass "${desc}"; else fail "${desc}"; fi
}

contains() { grep -qF -- "$2" "$1"; }

snapshot() {
  # Every regular file outside the volatile directories, with its checksum.
  find / -xdev \( -path /proc -o -path /sys -o -path /dev -o -path /run -o -path /tmp \) -prune \
    -o -type f -print0 | sort -z | xargs -0 md5sum
}

mkdir -p "${OUT}"
cp -r "${SRC}" "${WORK}"
# Normalize CRLF that can appear when the tree is bind-mounted from Windows.
find "${WORK}" -type f -name '*.sh' -exec sed -i 's/\r$//' {} +
chmod -R a+rX "${WORK}"
cd "${WORK}" || exit 2

export BOOTSTRAP_SSH_PUBKEY="${TEST_PUBKEY}"
export BOOTSTRAP_USER=deploy

# --- usage errors and environment checks ------------------------------------

printf 'ID=debian\nVERSION_ID="12"\n' >"${OUT}/os-debian"
printf 'ID=ubuntu\nVERSION_ID="20.04"\n' >"${OUT}/os-ubuntu20"

OS_RELEASE_FILE="${OUT}/os-debian" bash bootstrap.sh --dry-run >"${OUT}/debian.txt" 2>&1
status=$?
if [ "${status}" -ne 0 ] && contains "${OUT}/debian.txt" "unsupported OS 'debian'"; then
  pass "non-Ubuntu OS is refused with a clear message"
else
  fail "non-Ubuntu OS is refused with a clear message (exit ${status})"
fi

OS_RELEASE_FILE="${OUT}/os-ubuntu20" bash bootstrap.sh --dry-run >"${OUT}/ubuntu20.txt" 2>&1
status=$?
if [ "${status}" -ne 0 ] && contains "${OUT}/ubuntu20.txt" "unsupported Ubuntu version '20.04'"; then
  pass "unsupported Ubuntu version is refused with a clear message"
else
  fail "unsupported Ubuntu version is refused with a clear message (exit ${status})"
fi

runuser -u nobody -- bash bootstrap.sh >"${OUT}/nonroot.txt" 2>&1
status=$?
if [ "${status}" -ne 0 ] && contains "${OUT}/nonroot.txt" "must run as root"; then
  pass "non-root real run is refused with a clear message"
else
  fail "non-root real run is refused with a clear message (exit ${status})"
fi

# --- dry run changes nothing -------------------------------------------------

snapshot >"${OUT}/before.txt"
dpkg-query -W >"${OUT}/pkgs-before.txt"
BOOTSTRAP_FORCE_SWAP=1 bash bootstrap.sh --dry-run --skip ssh >"${OUT}/dry.txt" 2>&1
status=$?
snapshot >"${OUT}/after.txt"
dpkg-query -W >"${OUT}/pkgs-after.txt"

expect "dry run exits 0" test "${status}" -eq 0
[ "${status}" -eq 0 ] || tail -n 40 "${OUT}/dry.txt"
if cmp -s "${OUT}/before.txt" "${OUT}/after.txt"; then
  pass "dry run leaves every file unchanged (checksums)"
else
  fail "dry run leaves every file unchanged (checksums)"
  diff "${OUT}/before.txt" "${OUT}/after.txt" | head -n 20
fi
expect "dry run installs no packages" cmp -s "${OUT}/pkgs-before.txt" "${OUT}/pkgs-after.txt"
expect "dry run reports the fail2ban install it would do" contains "${OUT}/dry.txt" "would   install packages: fail2ban"
if contains "${OUT}/dry.txt" "fallocate -l 2G /swapfile" || contains "${OUT}/dry.txt" "swap is already configured"; then
  pass "dry run prints a swap plan or leaves existing swap alone"
else
  fail "dry run prints a swap plan or leaves existing swap alone"
fi
if contains "${OUT}/dry.txt" "/swapfile none swap sw 0 0" || contains "${OUT}/dry.txt" "swap is already configured"; then
  pass "dry run covers fstab swap line or existing swap"
else
  fail "dry run covers fstab swap line or existing swap"
fi
expect "dry run plans the deploy user" contains "${OUT}/dry.txt" "create user deploy"
expect "dry run plans docker" contains "${OUT}/dry.txt" "install packages: docker.io"
expect "dry run summary says what would change" contains "${OUT}/dry.txt" "change(s) would be made"

BOOTSTRAP_FORCE_SWAP=1 bash bootstrap.sh --dry-run --only ssh >"${OUT}/dry-ssh.txt" 2>&1
expect "ssh dry-run prints lockout warning" contains "${OUT}/dry-ssh.txt" "SSH HARDENING CAN LOCK YOU OUT"

# --- step selection ----------------------------------------------------------

bash bootstrap.sh --dry-run --only fail2ban >"${OUT}/only.txt" 2>&1
if contains "${OUT}/only.txt" "==> fail2ban" && ! contains "${OUT}/only.txt" "==> swap"; then
  pass "--only runs just the named step"
else
  fail "--only runs just the named step"
fi
bash bootstrap.sh --dry-run --skip fail2ban >"${OUT}/skip.txt" 2>&1
if contains "${OUT}/skip.txt" "==> fail2ban (skipped by --skip)" && contains "${OUT}/skip.txt" "==> swap"; then
  pass "--skip leaves out the named step"
else
  fail "--skip leaves out the named step"
fi

# --- real run (skip ssh), then a second run ----------------------------------

bash bootstrap.sh --skip ssh >"${OUT}/run1.txt" 2>&1
status=$?
expect "first real run exits 0" test "${status}" -eq 0
[ "${status}" -eq 0 ] || tail -n 40 "${OUT}/run1.txt"
expect "swap step skips itself in a container" contains "${OUT}/run1.txt" "running in a container, swap is managed by the host"
expect "ufw step skips itself in a container" contains "${OUT}/run1.txt" "running in a container, host firewall is out of scope"
expect "monitoring stays off by default" contains "${OUT}/run1.txt" "ENABLE_MONITORING is not 1"
expect "first run reports its changes" contains "${OUT}/run1.txt" "change(s) made"

for pkg in unattended-upgrades fail2ban logrotate docker.io caddy; do
  expect "package ${pkg} is installed" dpkg -s "${pkg}"
done
expect "deploy user exists" id -u deploy
expect "deploy has authorized_keys" test -s /home/deploy/.ssh/authorized_keys
if id -nG deploy | tr ' ' '\n' | grep -qx sudo; then
  pass "deploy is in the sudo group"
else
  fail "deploy is in the sudo group"
fi
if id -nG deploy | tr ' ' '\n' | grep -qx docker; then
  pass "deploy is in the docker group"
else
  fail "deploy is in the docker group"
fi
expect "20auto-upgrades enables unattended upgrades" grep -q 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades
expect "automatic reboot is off" grep -q 'Automatic-Reboot "false"' /etc/apt/apt.conf.d/52server-bootstrap-unattended-upgrades
expect "fail2ban jail file is written" grep -q '^\[sshd\]' /etc/fail2ban/jail.d/server-bootstrap.local
expect "fail2ban accepts its configuration" fail2ban-client -t
expect "journald limit is written" grep -q '^SystemMaxUse=500M' /etc/systemd/journald.conf.d/50-server-bootstrap.conf
expect "docker daemon log limits are written" grep -q '"max-size": "10m"' /etc/docker/daemon.json
expect "caddy placeholder is written" grep -q 'server-bootstrap placeholder' /etc/caddy/Caddyfile

# SSH without a confirmation must refuse once a key exists.
bash bootstrap.sh --only ssh >"${OUT}/ssh-refuse.txt" 2>&1
status=$?
if [ "${status}" -ne 0 ] && contains "${OUT}/ssh-refuse.txt" "BOOTSTRAP_CONFIRM_SSH=1"; then
  pass "ssh refuses without BOOTSTRAP_CONFIRM_SSH when non-interactive"
else
  fail "ssh refuses without BOOTSTRAP_CONFIRM_SSH when non-interactive (exit ${status})"
  tail -n 20 "${OUT}/ssh-refuse.txt"
fi

snapshot >"${OUT}/before2.txt"
bash bootstrap.sh --skip ssh >"${OUT}/run2.txt" 2>&1
status=$?
snapshot >"${OUT}/after2.txt"

expect "second run exits 0" test "${status}" -eq 0
[ "${status}" -eq 0 ] || tail -n 40 "${OUT}/run2.txt"
expect "second run reports no changes" contains "${OUT}/run2.txt" "No changes were needed"
grep -E '^  (change|would)' "${OUT}/run2.txt" || true
if cmp -s "${OUT}/before2.txt" "${OUT}/after2.txt"; then
  pass "second run leaves every file unchanged (checksums)"
else
  fail "second run leaves every file unchanged (checksums)"
  diff "${OUT}/before2.txt" "${OUT}/after2.txt" | head -n 20
fi
if find /etc -name '*.bak-*' | grep -q .; then
  # First run may have left backups; second run must not add new ones after the snapshot.
  pass "backup files may exist from the first run (checked via checksum identity above)"
else
  pass "second run created no backup files"
fi

# --- helper behaviour --------------------------------------------------------

(
  # shellcheck source=/dev/null
  . "${WORK}/lib/log.sh"
  . "${WORK}/lib/run.sh"
  . "${WORK}/lib/files.sh"
  f="${OUT}/fstab-test"
  printf 'first line without newline' >"${f}"
  ensure_line "${f}" "added line" >/dev/null
  [ "${FILE_CHANGED}" -eq 1 ] || exit 1
  ensure_line "${f}" "added line" >/dev/null
  [ "${FILE_CHANGED}" -eq 0 ] || exit 2
  [ "$(wc -l <"${f}")" -eq 2 ] || exit 3
  [ "$(sed -n 1p "${f}")" = "first line without newline" ] || exit 4
  ls "${f}".bak-* >/dev/null 2>&1 || exit 5
  ensure_file "${OUT}/managed" 600 "hello" >/dev/null
  [ "${FILE_CHANGED}" -eq 1 ] && [ "$(stat -c %a "${OUT}/managed")" = "600" ] || exit 6
  ensure_file "${OUT}/managed" 600 "hello" >/dev/null
  [ "${FILE_CHANGED}" -eq 0 ] || exit 7
  ensure_file "${OUT}/managed" 600 "changed" >/dev/null
  [ "${FILE_CHANGED}" -eq 1 ] && ls "${OUT}"/managed.bak-* >/dev/null 2>&1 || exit 8
)
helper_status=$?
expect "ensure_line and ensure_file are idempotent and back up (failed check: ${helper_status})" test "${helper_status}" -eq 0

if [ "${failures}" -ne 0 ]; then
  echo "${failures} check(s) failed"
  exit 1
fi
echo "all checks passed"
