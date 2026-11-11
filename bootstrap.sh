#!/usr/bin/env bash
set -euo pipefail

VERSION="0.0.1"

usage() {
  cat <<USAGE
Usage: bootstrap.sh [--dry-run] [--help] [--version]

Setup for a fresh Ubuntu VPS. No steps are implemented yet.

Options:
  --dry-run   Print what would be done without changing anything.
  --help      Show this help and exit.
  --version   Show the version and exit.
USAGE
}

DRY_RUN=0

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
    *)
      echo "bootstrap.sh: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "${DRY_RUN}" -eq 1 ]; then
  echo "dry-run: no steps are implemented yet, nothing to show."
else
  echo "No steps are implemented yet. Nothing was changed."
fi
