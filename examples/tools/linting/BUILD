load("@linting_rules//:rules.bzl", "linter")

package(default_visibility = ['//visibility:public'])

linter(
    name = "python",
    executable_path = "/usr/local/bin/black",
    config = "TODO",
    visibility = ["//visibility:public"],
)

linter(
    name = "golang",
    executable_path = "/usr/local/bin/gofmt",
    config = "TODO",
    visibility = ["//visibility:public"],
)

linter(
    name = "jsonnet",
    executable_path = "/usr/local/bin/jsonnetfmt",
    config = "TODO",
    visibility = ["//visibility:public"],
)