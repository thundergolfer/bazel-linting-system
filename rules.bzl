LinterInfo = provider(
    fields = {
        "executable_path": "Absolute path to the linter that will run",
        "executable": "Label for an executable linter",
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
        "executable_path": attr.string(
            doc="Absolute path to the linter that will run",
            mandatory=False,
        ),
        "executable": attr.label(
            executable=True,
            cfg="host",
            doc="Label for an executable linter",
        ),
        "config": attr.label(
            allow_single_file=True,
            doc="Configuration file for linter",
        ),
        "config_option": attr.string(
            doc="The option used by the linter to pass a path to a configuration file",
        ),
        "config_str": attr.string(
            doc="Raw string configuration options to be passed to linter",
        )
    },
)
