load("@bazel_skylib//lib:shell.bzl", "shell")

FileCountInfo = provider(
    fields = {
        'count' : 'number of files'
    }
)

def _file_count_aspect_impl(target, ctx):
    # Ignore rules in external repos
    if ctx.label.workspace_name:
        return []
    if not hasattr(ctx.rule.attr, 'srcs'):
        return  []

    print(ctx.label)
    out = ctx.actions.declare_file("%s.lint_report" % ctx.rule.attr.name)
    src_files = [
        file for src in ctx.rule.attr.srcs
        for file in src.files.to_list()
    ]
    cmd = "black {srcs} > {out}".format(
        out = shell.quote(out.path),
        srcs = " ".join([shell.quote(src_f.path) for src_f in src_files]),
    )
#    cmd = "echo 'hello world' > {out}".format(out=shell.quote(out.path))
    ctx.actions.run_shell(
        outputs = [out],
        inputs = src_files,
        command = cmd,
        mnemonic = "GoCompile",
        use_default_shell_env = True,
        progress_message = "Linting with black: {srcs}".format(srcs=" ".join([src_f.path for src_f in src_files]))
    )
    # TODO(Jonathon): Should this provide something?
    print(out.path)
    return [
        DefaultInfo(files = depset([out])),
        OutputGroupInfo(
            report = depset([out]),
        )
    ]

file_count_aspect = aspect(implementation = _file_count_aspect_impl,
    attr_aspects = ['deps'],
#    attrs = {
#        'extension' : attr.string(default = '*'),
#    }
)

def _file_count_rule_impl(ctx):
    for dep in ctx.attr.deps:
        print(dep[FileCountInfo].count)

file_count_rule = rule(
    implementation = _file_count_rule_impl,
    attrs = {
        'deps' : attr.label_list(aspects = [file_count_aspect]),
    },
)