load("//:rules.bzl", "linter")

linter(
    name = "no-op",
    executable_path = "",
    visibility = ["//visibility:public"],
)

alias(
    name = "apply_changes",
    actual = "//apply_changes",
)

exports_files(["lint.sh.TEMPLATE"])