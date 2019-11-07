load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_test", "go_library")

go_library(
    name = "main",
    srcs = ["main.go"],
    deps = [],
    importpath = "github.com/thundergolfer/bazel-linting-rules/example",
)

go_test(
    name = "test",
    srcs = ["main_test.go"],
    importpath = "github.com/thundergolfer/bazel-linting-rules/example",
    embed = [":main"],
)

go_binary(
    name = "server",
    srcs = ["main.go"],
)
