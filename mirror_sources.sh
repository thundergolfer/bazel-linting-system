#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROG=$(basename "$0")

info() {
  echo "$(date '+[%Y-%m-%d %H:%M:%S]') ${PROG}: INFO: $*"
}

main() {
  local suffix
  local destination
  local files
  local mirrored_filepath
  local parts

  suffix="${1}"
  destination="${2}"
  shift 2

  in_out_pairs=("$@")

  for pair in "${in_out_pairs[@]}"; do
    arr_pair=(${pair//;/ })

    info "Copying ${arr_pair[0]} to ${arr_pair[1]}"
    mkdir -p "$(dirname "${arr_pair[1]}")"
    cp "${arr_pair[0]}" "${arr_pair[1]}"
  done
}

main "$@"