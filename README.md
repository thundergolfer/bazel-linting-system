<h1 align="center">🪦 Archived 🪦</h1>

<p align="center">
  <h3 align="center">Check out <a href="">aspect-build/<strong>bazel-super-formatter</strong></a> instead.</h3>
</p>


----

<p align="center">
  <img src="https://media.giphy.com/media/hV6TgQmCoxxyItBFHx/giphy.gif"/>
</p>

# `bazel-linting-system`

This is an experimental project with the goals of providing a simple tool for linting source code within a polyglot Bazel repo
and learning more about aspects. 

### Will this work with linting tool `X`?

This project was designed with linters like [`black`](https://github.com/psf/black) and [`gofmt`](https://golang.org/cmd/gofmt/) in mind. Given their behaviour, they're perhaps more accurately called _formatters_, but to me formatters are a subclass of linters. 

If a linting tool restricts itself to only doing evaluation using your source code files, without needing access to any other information like dependencies or compiler-configuration then it will fit nicely into this project. I think of this project's model linter as a pure function from a source code file to a linted source code file: `f(source_code: str) -> str`.

Now this restriction does allow for things beyond formatting, for example you can check for unused variables, unused imports, or missing return values. But some powerful static analysis tools are outside of project scope, like [`mypy`](https://github.com/thundergolfer/bazel-mypy-integration).

⚠️ _Currently linters also must be able to modify source 'in-place'._ Thankfully most linters can do this.  

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
    strip_prefix = "bazel-linting-system-0.4.0",
    url = "https://github.com/thundergolfer/bazel-linting-system/archive/v0.4.0.zip",
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
