# shellcheck shell=bash
# Step: swap
# Protects against: the kernel OOM killer stopping services when a small VPS runs out of memory.
# Re-run: does nothing if any swap is already active.
# Dry-run: prints the commands it would run.
#
# Containers cannot create swap (the host owns it), so the step skips itself
# there. BOOTSTRAP_FORCE_SWAP=1 disables that skip; it exists so the dry-run
# plan can be tested in a container.

SWAP_FILE="${SWAP_FILE:-/swapfile}"
SWAP_SIZE="${SWAP_SIZE:-2G}"

step_swap() {
  local active need avail
  if in_container && [ "${BOOTSTRAP_FORCE_SWAP:-0}" != "1" ]; then
    log_ok "running in a container, swap is managed by the host, skipping"
    return 0
  fi

  active="$(swapon --noheadings --show=NAME 2>/dev/null || true)"
  if grep -qxF -- "${SWAP_FILE}" <<<"${active}"; then
    log_ok "${SWAP_FILE} is active"
  elif [ -n "${active}" ]; then
    log_ok "swap is already configured (${active//$'\n'/, }), leaving it alone"
    return 0
  else
    need="$(numfmt --from=iec "${SWAP_SIZE}")"
    avail="$(df --output=avail -B1 / | tail -n 1 | tr -d ' ')"
    # Keep 1 GiB free after the swap file so the disk does not fill up.
    if [ "${avail}" -lt $((need + 1073741824)) ]; then
      die "not enough free disk space for a ${SWAP_SIZE} swap file on /"
    fi
    if [ -e "${SWAP_FILE}" ]; then
      if [ "$(blkid -p -o value -s TYPE "${SWAP_FILE}" 2>/dev/null || true)" != "swap" ]; then
        die "${SWAP_FILE} exists but is not a swap file. Move it away or set SWAP_FILE"
      fi
      log_change "activate existing swap file ${SWAP_FILE}"
    else
      log_change "create ${SWAP_SIZE} swap file ${SWAP_FILE}"
      # fallocate works on ext4 and xfs, the default on common VPS images.
      run fallocate -l "${SWAP_SIZE}" "${SWAP_FILE}"
      run chmod 600 "${SWAP_FILE}"
      run mkswap "${SWAP_FILE}"
    fi
    run swapon "${SWAP_FILE}"
  fi

  ensure_line /etc/fstab "${SWAP_FILE} none swap sw 0 0"
}
