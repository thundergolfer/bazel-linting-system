load("//:rules.bzl", "linter")

linter(
    name = "no-op",
    executable_path = "",
    visibility = ["//visibility:public"],
)

#sh_binary(
#    name = "apply_changes",
#    srcs = ["apply_changes.sh"],
#    visibility = ["//visibility:public"],
#)

alias(
    name = "apply_changes",
    actual = "//apply_changes",
)

exports_files(["lint.sh.TEMPLATE"])