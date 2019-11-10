LinterInfo = provider(
    fields = {
        "executable_path": "Absolute path to the linter that will run",
        "executable": "An executable File the run the linter",
        "config": "Configuration file for linter",
        "config_option": "The option used by the linter to pass a path to a configuration file",
        "config_str": "Raw string configuration options to be passed to linter",
    }
)


def _linter_impl(ctx):
    return [
        LinterInfo(
            executable_path=ctx.attr.executable_path,
            executable=ctx.executable.executable,
            config=ctx.file.config,
            config_option=ctx.attr.config_option,
            config_str=ctx.attr.config_str,
        )
    ]


linter = rule(
    implementation = _linter_impl,
    attrs = {
# TODO  "executable": attr.label,
        "executable_path": attr.string(
            doc="TODO(Jonathon)"
        ),
        "executable": attr.label(
            allow_single_file=True,
            doc="TODO(Jonathon)",
        )
        "config": attr.label(
            allow_single_file=True,
            doc="TODO(Jonathon)"
        ),
        "config_option": attr.string(
            doc="TODO(Jonathon)"
        ),
        "config_str": attr.string(
            doc="TODO(Jonathon)"
        )
    },
)