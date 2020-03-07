load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

def go_deps():
    """Pull in external Go packages needed by Go binaries in this repo.
    Pull in all dependencies needed to build the Go binaries in this
    repository. This function assumes the repositories imported by the macro
    'repositories' in //repositories:repositories.bzl have been imported
    already.
    """
    go_rules_dependencies()
    go_register_toolchains()
