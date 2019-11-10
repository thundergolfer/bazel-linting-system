#!/usr/bin/env bash

#set -o errexit
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

  workspace_genfiles_root="$(bazel info bazel-genfiles)"

  echo "${REPO_ROOT}"

  cd "${REPO_ROOT}"

  # shellcheck disable=SC2207
  targets=($(bazel query //...))

  for t in "${targets[@]}"; do
      echo "${t}"
      clean="${t:2}" # remove leading '//'
      # shellcheck disable=SC2206
      pair=(${clean//:/ })
      package=${pair[0]}
      name=${pair[1]}

      echo "${package}"
      echo "${name}"

      find "${workspace_genfiles_root}/${package}/__linting_rules/" -name "*.linted" 2> /dev/null
  done
}

main "$@"