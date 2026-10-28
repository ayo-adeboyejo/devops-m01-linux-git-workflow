#!/usr/bin/env bash
#
# backup.sh - Back up a directory to a timestamped, compressed archive.
#
# Usage: backup.sh <source-dir> [destination-dir]

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/backup.log"

# Usage function
usage() {
  echo "Usage: ${SCRIPT_NAME} <source-dir> [destination-dir]" >&2
}


# log function
log() {
  local log_level="$1" # e.g INFO, ERROR, DEBUG, WARN
  shift
  local log_line
  log_line="$(date '+%Y-%m-%d %H:%M:%S') [${log_level}] $*"
  echo "${log_line}" >> "${LOG_FILE}"
  if [[ "${log_level}" == "ERROR" ]]; then
    echo "${log_line}" >&2
  else
    echo "${log_line}"
  fi
}

# Log an error and stop with exit code 2
exit_with_error() {
  log ERROR "$*"
  exit 2
}


# Check the source can be backed up
validate_source() {
  local source_dir="$1"
  [[ -e "${source_dir}" ]] || exit_with_error "Source not found: ${source_dir}"
  [[ -d "${source_dir}" ]] || exit_with_error "Source is not a directory: ${source_dir}"
  [[ -r "${source_dir}" && -x "${source_dir}" ]] || exit_with_error "Source is not readable: ${source_dir}"
}



# Check the destination is not in the source, then create it
prepare_destination() {
  local source_dir="$1"
  local dest_dir="$2"
  case "${dest_dir}/" in
    "${source_dir}/"*) exit_with_error "Destination is inside the source directory: ${dest_dir}" ;;
  esac
  mkdir -p "${dest_dir}" || exit_with_error "Cannot create destination: ${dest_dir}"
  [[ -w "${dest_dir}" ]] || exit_with_error "Destination is not writable: ${dest_dir}"
}




# main function
main() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 1
  fi

  local source_dir="$1"
  local dest_dir="${2:-${PROJECT_ROOT}/backups}"

  mkdir -p "${LOG_DIR}"
  log INFO "Starting backup: ${source_dir} -> ${dest_dir}"
}

main "$@"
