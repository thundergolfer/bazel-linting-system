
LinterInfo = provider(
    fields = {
        "executable_path": "Absolute path to the linter that will run",
        "config": "Configuration file for linter",
    }
)



def _linter_impl(ctx):
    return [
        LinterInfo(
            executable_path=ctx.attr.executable_path,
            config=ctx.file.config,
        )
    ]



linter = rule(
    implementation = _linter_impl,
    attrs = {
# TODO  "executable": attr.label,
        "executable_path": attr.string(),
        "config": attr.label(allow_single_file=True)
    },
)