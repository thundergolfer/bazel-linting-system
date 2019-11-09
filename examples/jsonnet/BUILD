load("@io_bazel_rules_jsonnet//jsonnet:jsonnet.bzl", "jsonnet_library", "jsonnet_to_json")

jsonnet_library(
    name = "martinis",
    srcs = [
        "martinis.libsonnet",
    ],
)

jsonnet_to_json(
    name = "cocktails",
    src = "cocktails.jsonnet",
    deps = [
        ":martinis",
    ],
    outs = ["cocktails.json"],
)