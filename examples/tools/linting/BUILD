load("@linting_rules//:rules.bzl", "linter")

package(default_visibility = ['//visibility:public'])

linter(
    name = "python",
    executable_path = "/usr/local/bin/black",
    config = ":configuration/pyproject.toml",
    config_option = "--config",
    visibility = ["//visibility:public"],
)

linter(
    name = "golang",
    executable_path = "/usr/local/bin/gofmt",
    visibility = ["//visibility:public"],
)

linter(
    name = "jsonnet",
    executable_path = "/usr/local/bin/jsonnetfmt",
    config_str = "--in-place --string-style d --comment-style s",
    visibility = ["//visibility:public"],
)