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

usage() {
  echo "Usage: ${SCRIPT_NAME} <source-dir> [destination-dir]" >&2
}

log() {
  local log_level="$1"
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

# Check the destination is safe, then create it
prepare_destination() {
  local source_dir="$1"
  local dest_dir="$2"
  case "${dest_dir}/" in
    "${source_dir}/"*) exit_with_error "Destination is inside the source directory: ${dest_dir}" ;;
  esac
  mkdir -p "${dest_dir}" || exit_with_error "Cannot create destination: ${dest_dir}"
  [[ -w "${dest_dir}" ]] || exit_with_error "Destination is not writable: ${dest_dir}"
}

# Create a verified, timestamped archive of the source
create_backup() {
  local source_dir="$1"
  local dest_dir="$2"
  local timestamp archive_name archive_path temp_path archive_size

  timestamp="$(date '+%Y%m%d_%H%M%S')"
  archive_name="$(basename "${source_dir}")_${timestamp}.tar.gz"
  archive_path="${dest_dir}/${archive_name}"
  temp_path="${archive_path}.part"

  [[ ! -e "${archive_path}" ]] || exit_with_error "Archive already exists: ${archive_path}"

  if ! tar -czf "${temp_path}" -C "$(dirname "${source_dir}")" "$(basename "${source_dir}")"; then
    rm -f -- "${temp_path}"
    exit_with_error "tar failed while archiving: ${source_dir}"
  fi

  if ! tar -tzf "${temp_path}" > /dev/null; then
    rm -f -- "${temp_path}"
    exit_with_error "Archive failed verification: ${temp_path}"
  fi

  mv -- "${temp_path}" "${archive_path}"

  archive_size="$(du -h -- "${archive_path}" | cut -f1)"
  log INFO "Backup OK: ${source_dir} -> ${archive_path} (${archive_size})"
}

main() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 1
  fi

  # make new files and folders private to the owner
  umask 077

  mkdir -p "${LOG_DIR}"

  # Convert both paths to absolute paths before checking them
  local source_dir dest_dir
  source_dir="$(realpath -m -- "$1")"
  dest_dir="$(realpath -m -- "${2:-${PROJECT_ROOT}/backups}")"

  validate_source "${source_dir}"
  prepare_destination "${source_dir}" "${dest_dir}"

  log INFO "Starting backup: ${source_dir} -> ${dest_dir}"
  create_backup "${source_dir}" "${dest_dir}"
}

main "$@"
