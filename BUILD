load("//:rules.bzl", "linter")

linter(
    name = "no-op",
    executable_path = "",
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "mirror_sources",
    srcs = ["mirror_sources.sh"],
    visibility = ["//visibility:public"],
)

exports_files(["lint.sh.TEMPLATE"])