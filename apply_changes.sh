#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROG=$(basename "$0")

info() {
  echo "$(date '+[%Y-%m-%d %H:%M:%S]') ${PROG}: INFO: $*"
}

main() {
  local clean
  local pair
  local package
  local name
  local workspace_genfiles_root
  local linted_files_dir
  local files_to_overwrite
  local repo_relative_filepath

  cd "${REPO_ROOT}"
  # shellcheck disable=SC2207
  targets=($(bazel query //...))

  for t in "${targets[@]}"; do
      clean="${t:2}" # remove leading '//'
      # shellcheck disable=SC2206
      pair=(${clean//:/ })
      package=${pair[0]}
      name=${pair[1]}

      linted_files_dir="${BAZEL_BINDIR}/${package}/__linting_rules/${name}"
      if [[ -d "${linted_files_dir}" ]];
      then
          # shellcheck disable=SC2207
          files_to_overwrite=($(find "${linted_files_dir}" -type f ))
          for f in "${files_to_overwrite[@]}"; do
            repo_relative_filepath=${f#"${linted_files_dir}/"}
#            echo "would overwrite -> ${repo_relative_filepath}"
            cp "${f}" "${REPO_ROOT}/${repo_relative_filepath}"
          done
      fi
  done
}

main "$@"