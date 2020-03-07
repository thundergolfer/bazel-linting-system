"""Rules to load all dependencies of bazel-linting-system."""

load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
    "http_file",
)

def repositories():
    """Download dependencies of container rules."""
    excludes = native.existing_rules().keys()

    if "io_bazel_rules_go" not in excludes:
            http_archive(
                name = "io_bazel_rules_go",
                sha256 = "af04c969321e8f428f63ceb73463d6ea817992698974abeff0161e069cd08bd6",
                urls = [
                    "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v0.21.3/rules_go-v0.21.3.tar.gz",
                    "https://github.com/bazelbuild/rules_go/releases/download/v0.21.3/rules_go-v0.21.3.tar.gz",
                ],
            )

    if "bazel_skylib" not in excludes:
            http_archive(
                name = "bazel_skylib",
                sha256 = "e5d90f0ec952883d56747b7604e2a15ee36e288bb556c3d0ed33e818a4d971f2",
                strip_prefix = "bazel-skylib-1.0.2",
                urls = ["https://github.com/bazelbuild/bazel-skylib/archive/1.0.2.tar.gz"],
            )
