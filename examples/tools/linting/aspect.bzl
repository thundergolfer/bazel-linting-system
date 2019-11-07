load("@linting_rules//:generator.bzl", "linting_aspect_generator")

lint = linting_aspect_generator(
    name = "lint",
    linters = [
        "@//tools/linting:python_linter",
        "@//tools/linting:go_linter",
    ]
)
