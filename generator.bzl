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
        linter = ctx.attr._python_linter
    elif kind in ["go_library", "go_binary", "go_test"]:
        linter =  ctx.attr._golang_linter
    elif kind in ["jsonnet_library", "jsonnet_to_json"]:
        linter = ctx.attr._jsonnet_linter
    else:
        linter = None

    if linter != None and str(linter.label) == "@linting_rules//:no-op":
        linter = None

    if linter == None:
        debug("No linter for rule kind: {}".format(kind))
    return linter


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

    src_files = []
    if hasattr(ctx.rule.attr, 'srcs'):
        src_files += _gather_srcs(ctx.rule.attr.srcs)
    if hasattr(ctx.rule.attr, 'src'):
        src_files += _gather_srcs([ctx.rule.attr.src])

    # Note: Don't add ctx.label.package to prefix as it is implicitly added
    prefix = "__linting_rules/" + ctx.label.name

    outputs = []
    for f in src_files:
        declared_path = "{}/{}".format(prefix, f.path)
        print(declared_path)
        o = ctx.actions.declare_file(declared_path)
        outputs.append(o)

    pairs = [
        "{};{}".format(left, right) for left, right in
        zip([f.path for f in src_files], [o.path for o in outputs])
    ]

    report_out = ctx.actions.declare_file("%s.lint_report" % ctx.rule.attr.name)
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

    progress_msg = "Linting with {linter}: {srcs}".format(
        linter=linter_name,
        srcs=" ".join([src_f.path for src_f in src_files])
    )

    linter_inputs = src_files
    if linter_config:
        linter_inputs.append(linter_config)

    linter_template_expanded_exe = ctx.actions.declare_file(
        "%s_linter_exe" % ctx.rule.attr.name
    )
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = linter_template_expanded_exe,
        substitutions = {
            "{LINTER_EXE}": linter_exe,
            "{LINTER_EXE_CONFIG}": configuration,
            "{LINTER_SRCS}": " ".join([
                shell.quote(o.path) for
                o in outputs
            ]),
            "{REPORT}": shell.quote(report_out.path),
        },
        is_executable = True,
    )

    ctx.actions.run(
        outputs = outputs + [report_out],
        inputs = linter_inputs,
        executable = linter_template_expanded_exe,
        arguments = ["{}/{}".format(ctx.label.package, prefix)] + pairs,
        mnemonic = "MirrorAndLint",
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(files = depset(outputs + [report_out])),
        OutputGroupInfo(
            report = depset(outputs + [report_out]),
        )
    ]


def linting_aspect_generator(
        name,
        linters,
):
    linters_map = { lang: "@linting_rules//:no-op" for lang in SUPPORTED_LANGUAGES }
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
            '_template' : attr.label(
                default = Label('@linting_rules//:lint.sh.TEMPLATE'),
                allow_single_file = True,
            ),
            # LINTERS
            '_python_linter' : attr.label(
                default = linters_map["python"],
            ),
            '_golang_linter' : attr.label(
                default = linters_map["golang"],
            ),
            '_jsonnet_linter' : attr.label(
                default = linters_map["jsonnet"],
            ),
        },
    )