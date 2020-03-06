#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PROG=$(basename "$0")

main() {
  local clean
  local pair
  local package
  local name
  local workspace_genfiles_root
  local linted_files_dir
  local files_to_overwrite
  local repo_relative_filepath

  local repo_root=${1}
  local bazel_bindir=${2}
  local targets

  read -r -a targets <<< "${3}"

  cd "${repo_root}"
  # shellcheck disable=SC2207

  for t in "${targets[@]}"; do
      clean="${t:2}" # remove leading '//'
      # shellcheck disable=SC2206
      pair=(${clean//:/ })

      if [ ${#pair[@]} -eq 0 ]; then
        continue
      elif [ ${#pair[@]} -eq 1 ]; then
        package=""
        name=${pair[0]}
      else
        package="${pair[0]}/"
        name=${pair[1]}
      fi

      linted_files_dir="${bazel_bindir}/${package}__linting_system/${name}"
      if [[ -d "${linted_files_dir}" ]];
      then
          # shellcheck disable=SC2207
          files_to_overwrite=($(find "${linted_files_dir}" -type f ))
          for f in "${files_to_overwrite[@]}"; do
            repo_relative_filepath=${f#"${linted_files_dir}/"}
            cp "${f}" "${repo_root}/${repo_relative_filepath}"
          done
      fi
  done
}

main "$@"
