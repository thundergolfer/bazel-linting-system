load("@linting_rules//:rules.bzl", "linter")

package(default_visibility = ['//visibility:public'])

linter(
    name = "python_linter",
    executable_path = "/usr/local/bin/black",
    config = "TODO",
    visibility = ["//visibility:public"],
    language = ["PYTHON"],
)

linter(
    name = "go_linter",
    executable_path = "/usr/local/bin/black",
    config = "TODO",
    visibility = ["//visibility:public"],
    language = ["GOLANG"]
)