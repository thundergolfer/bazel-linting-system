load("@linting_rules//:rules.bzl", "linter")

package(default_visibility = ['//visibility:public'])

linter(
    name = "python",
    executable_path = "/usr/local/bin/black",
    config = ":configuration/pyproject.toml",
    config_option = "--config",
)

linter(
    name = "golang",
    executable_path = "/usr/local/bin/gofmt",
    config_str = "-w",
)

linter(
    name = "jsonnet",
    executable_path = "/usr/local/bin/jsonnetfmt",
    config_str = "--in-place --string-style d --comment-style s",
)

RUBY_LINTER_OPTS = " ".join([
    "--auto-correct", # Need to activate 'in-place' editing mode
    "--cache false",  # Rubocop's caching does not work with Bazel, and isn't necessary
    "--fail-level F", # Stop Rubocop exit-code=1
])

# TODO(Jonathon): Add a Rubocop configuration file
linter(
    name = "ruby",
    executable = "@rubocop//:exe",
#    executable_path = "/usr/local/lib/ruby/gems/2.6.0/bin/rubocop",
    config_str = RUBY_LINTER_OPTS,
)