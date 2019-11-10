#!/usr/bin/env bash

# lint.sh demonstrates the functionality of bazel-linting-rules.
# It will lint all source files in the repository, selecting
# the appropriate linter according to the language of the source code.
#
# bazel-linting-rules is setup to do in-place modifications to source files,
# so after running lint.sh the natural next steps are either to commit any changes
# made by it, or if in a Continuous Integration (CI) build/pipeline, check whether any
# changes resulted from linting and fail the build/pipeline.
#
# ci-lint-check.sh demonstrates an appropriate CI usage of bazel-linting-rules.

REPO_ROOT="$(git rev-parse --show-toplevel)/examples"

set -o errexit
set -o nounset
set -o pipefail

bazel build //... \
    --aspects //tools/linting:aspect.bzl%lint \
    --output_groups=report

bazel run @linting_rules//:apply_changes -- \
  "$(git rev-parse --show-toplevel)/examples" \
  "$(bazel info bazel-genfiles)" \
  "$(bazel query //... | tr '\n' ' ')"
