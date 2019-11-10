load("@linting_rules//:generator.bzl", "linting_aspect_generator")

lint = linting_aspect_generator(
    name = "lint",
    linters = [
        "@//tools/linting:python",
        "@//tools/linting:golang",
        "@//tools/linting:jsonnet",
        "@//tools/linting:ruby",
    ]
)
