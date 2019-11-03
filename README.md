# bazel-linting-rules



## Usage

Example usage with [`thundergolfer/the-one-true-bazel-monorepo`](https://github.com/thundergolfer/the-one-true-bazel-monorepo):

#### Setup

Create an `aspect.bzl` extension file in a folder called `tools/linting` with the following:

```python
load("@linting_rules//:generator.bzl", "linting_aspect_generator")

lint = linting_aspect_generator(
    name = "lint",
    linters = [
        "@//tools/linting:python",
    ]
)
```

`"@//tools/linting:python"` is a label reference to target in a sibling `BUILD` file, for example:

```python
load("@linting_rules//:rules.bzl", "linter")

package(default_visibility = ['//visibility:public'])

linter(
    name = "python",
    executable_path = "/usr/local/bin/black",
    config = "TODO(Jonathon): Allow passing config file",
    visibility = ["//visibility:public"]
)
```

`linter` targets define a path to the linter executable and optionally a config file for that linter.

Run with: 

```
bazel build //fruit_sorting/... \
    --aspects //tools/linting:aspect.bzl%lint \
    --output_groups=report \
    --define=repo_root=$(git rev-parse --show-toplevel)
```