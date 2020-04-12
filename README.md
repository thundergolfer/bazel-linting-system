<p align="center">
  <img src="https://media.giphy.com/media/hV6TgQmCoxxyItBFHx/giphy.gif"/>
</p>

# `bazel-linting-system`

This is an experimental project with the goals of providing a simple tool for linting source code within a polyglot Bazel repo
and learning more about aspects. ⚠️ _Currently it relies on being able to configure your linters to modify source 'in-place'._ Thankfully most linters can do this.  

See [`DESIGN.md`](DESIGN.md) for some discussion of the pros/cons of this project. 

## Usage

An example Bazel workspace exists in [`examples`](/examples), with a `lint.sh` that runs the registered linters against 
all source code within the workspace.

Below is further explanation of the constituents of this system.

#### Setup

Add the following to your WORKSPACE file: 

```python
http_archive(
    name = "linting_system",
    sha256 = "",
    strip_prefix = "bazel-linting-system-0.3.0",
    url = "https://github.com/thundergolfer/bazel-linting-system/archive/v0.3.0.zip",
)

load("@linting_system//repositories:repositories.bzl", linting_sys_repositories = "repositories")
linting_sys_repositories()

load("@linting_system//repositories:go_repositories.bzl", linting_sys_deps = "go_deps")
linting_sys_deps()
```

Create an `aspect.bzl` extension file in a folder called `tools/linting` with the following:

```python
load("@linting_system//:generator.bzl", "linting_aspect_generator")

lint = linting_aspect_generator(
    name = "lint",
    linters = [
        "@//tools/linting:python",
    ]
)
```

`"@//tools/linting:python"` is a label reference to target in a sibling `BUILD` file, for example:

```python
load("@linting_system//:rules.bzl", "linter")

package(default_visibility = ['//visibility:public'])

linter(
    name = "python",
    executable_path = "/usr/local/bin/black",
    config = ":configuration/pyproject.toml",
    config_option = "--config",
)
```

`linter` targets define a path to the linter executable and optionally a config file for that linter.

> ⚠️ The **`name`** field in the `linter` rule must exactly match one of the supported languages. The list of supported languages is 
> shown at the top of [`generator.bzl`](generator.bzl).

Run with: 

```shell script
bazel build //... \
    --aspects //tools/linting:aspect.bzl%lint \
    --output_groups=report

bazel run @linting_system//apply_changes -- \
  "$(git rev-parse --show-toplevel)" \
  "$(bazel info bazel-genfiles)"

```

Usually you'll want to wrap up the above in a simple script named something like `lint.sh`. 

You can also add the aspect to your `.bazelrc` 🎉: 

```
build --aspects //tools/linting:aspect.bzl%lint
build --output_groups=+report
```
