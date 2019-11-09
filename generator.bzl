load("@bazel_skylib//lib:shell.bzl", "shell")
load("//:rules.bzl", "LinterInfo")


SUPPORTED_LANGUAGES = [
    "python",
    "golang",
    "jsonnet",
]

# Aspects that accept parameters cannot be called on the command line.
# As I want to call the linter aspect on the command line I can't pass parameters.
# Thus, I can't pass a 'debug' parameter to the aspect.
# So here I make a global to allow switching DEBUG logs on an off
DEBUG=True

def debug(msg):
    if DEBUG:
        print(msg)


def both_or_neither(l, r):
    return (l and r) or (not l and not r)



def _select_linter(ctx):
    kind = ctx.rule.kind
    if kind in ["py_library", "py_binary", "py_test"]:
        return ctx.attr._python_linter
    elif kind in ["go_library", "go_binary", "go_test"]:
        return ctx.attr._golang_linter
    elif kind in ["jsonnet_library", "jsonnet_to_json"]:
        return ctx.attr._jsonnet_linter
    debug("No linter for rule kind: {}".format(kind))
    return None


def _gather_srcs(src_lst):
    return [
        file for src in src_lst
        for file in src.files.to_list()
    ]

def _lint_workspace_aspect_impl(target, ctx):
    no_source_files = (
        not hasattr(ctx.rule.attr, 'srcs') and
        not hasattr(ctx.rule.attr, 'src')
    )

    if (
        # Ignore targets in external repos
        ctx.label.workspace_name or
        # Ignore targets without source files
        no_source_files
    ):
        return  []

    linter = _select_linter(ctx)
    if not linter:
        return []

    repo_root = ctx.var["repo_root"]

    out = ctx.actions.declare_file("%s.lint_report" % ctx.rule.attr.name)

    src_files = []
    if hasattr(ctx.rule.attr, 'srcs'):
        src_files += _gather_srcs(ctx.rule.attr.srcs)
    if hasattr(ctx.rule.attr, 'src'):
        src_files += _gather_srcs([ctx.rule.attr.src])

    linter_exe = linter[LinterInfo].executable_path
    linter_name = linter_exe.split("/")[-1]
    linter_config_opt = linter[LinterInfo].config_option
    linter_config = linter[LinterInfo].config
    linter_config_str = linter[LinterInfo].config_str

    if not both_or_neither(linter_config, linter_config_opt):
        fail_msg = (
            "When specifying linter configuration for {},".format(linter_name) +
            "both 'config_option' and 'config' must be specified."
        )
        fail(msg=fail_msg)

    if linter_config_str and linter_config:
        fail(msg="Don't both specify a config file and raw string config")

    if linter_config:
        configuration = "{} {}".format(
            linter_config_opt,
            shell.quote(linter_config.path),
        )
    elif linter_config_str:
        configuration = linter_config_str
    else:
        configuration = ""


    cmd = "{linter_exe} {config} {srcs} > {out}".format(
        linter_exe = linter_exe,
        config = configuration,
        srcs = " ".join([
            shell.quote("{}/{}".format(repo_root, src_f.path)) for
            src_f in src_files
        ]),
        out = shell.quote(out.path),
    )
    debug("Running: \"{}\"".format(cmd))

    progress_msg = "Linting with {linter}: {srcs}".format(
        linter=linter_name,
        srcs=" ".join([src_f.path for src_f in src_files])
    )

    ctx.actions.run_shell(
        outputs = [out],
        inputs = src_files,
        command = cmd,
        mnemonic = "Lint",
        use_default_shell_env = True,
        progress_message = progress_msg,
        execution_requirements = {
            "no-sandbox": "1",
        }
    )

    return [
        DefaultInfo(files = depset([out])),
        OutputGroupInfo(
            report = depset([out]),
        )
    ]


def linting_aspect_generator(
        name,
        linters,
):
    linters_map = { lang: None for lang in SUPPORTED_LANGUAGES }
    for l in linters:
        linter_label = Label(l)
        # TODO(Jonathon): Don't allow double-writing to single language (ie. duplicate linters)
        if linter_label.name not in SUPPORTED_LANGUAGES:
            err_msg = "Linter label names must match exactly a support language. Supported: {}".format(SUPPORTED_LANGUAGES)
            fail(err_msg)
        linters_map[linter_label.name] = linter_label

    return aspect(
        implementation = _lint_workspace_aspect_impl,
        attr_aspects = [],
        attrs = {
            '_python_linter' : attr.label(
                default = linters_map["python"],
            ),
            '_golang_linter' : attr.label(
                default = linters_map["golang"],
            ),
            '_jsonnet_linter' : attr.label(
                default = linters_map["jsonnet"],
            ),
        }
    )