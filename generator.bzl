# Changed 2020 by Zenseact AB

load("@bazel_skylib//lib:shell.bzl", "shell")
load("//:rules.bzl", "LinterInfo")


SUPPORTED_LANGUAGES = [
    "python",
    "golang",
    "jsonnet",
    "ruby",
    "rust",
    "cc",
]

# Aspects that accept parameters cannot be called on the command line.
# As I want to call the linter aspect on the command line I can't pass parameters.
# Thus, I can't pass a 'debug' parameter to the aspect.
# So here I make a global to allow switching DEBUG logs on an off
DEBUG=False

def debug(msg):
    if DEBUG:
        print(msg)



def _select_linter(ctx):
    kind = ctx.rule.kind
    if kind in ["py_library", "py_binary", "py_test"]:
        linter = ctx.attr._python_linter
    elif kind in ["go_library", "go_binary", "go_test"]:
        linter =  ctx.attr._golang_linter
    elif kind in ["jsonnet_library", "jsonnet_to_json"]:
        linter = ctx.attr._jsonnet_linter
    elif kind in ["ruby_library", "ruby_binary", "ruby_test"]:
            linter = ctx.attr._ruby_linter
    elif kind in ["rust_library", "rust_binary", "rust_test"]:
            linter = ctx.attr._rust_linter
    elif kind in ["cc_library", "cc_binary", "cc_test"]:
        linter =  ctx.attr._cc_linter
    else:
        linter = None

    if linter == None:
        debug("No linter for rule kind: {}".format(kind))

    if linter != None and str(linter.label) == "@linting_system//:no-op":
        linter = None

    return linter


def _gather_srcs(src_lst):
    return [
        file for src in src_lst
        for file in src.files.to_list()
    ]

def _lint_workspace_aspect_impl(target, ctx):
    no_source_files = (
        not hasattr(ctx.rule.attr, 'hdrs') and
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

    src_files = []
    if hasattr(ctx.rule.attr, 'hdrs'):
        src_files += _gather_srcs(ctx.rule.attr.hdrs)
    if hasattr(ctx.rule.attr, 'srcs'):
        src_files += _gather_srcs(ctx.rule.attr.srcs)
    if hasattr(ctx.rule.attr, 'src'):
        src_files += _gather_srcs([ctx.rule.attr.src])

    # Note: Don't add ctx.label.package to prefix as it is implicitly added
    prefix = "__linting_system/" + ctx.label.name

    outputs = []
    for f in src_files:
        declared_path = "{}/{}".format(prefix, f.path)
        o = ctx.actions.declare_file(declared_path)
        outputs.append(o)

    pairs = [
        "{};{}".format(left, right) for left, right in
        zip([f.path for f in src_files], [o.path for o in outputs])
    ]

    report_out = ctx.actions.declare_file("%s.lint_report" % ctx.rule.attr.name)

    linter_exe = linter[LinterInfo].executable_path or \
                 linter[LinterInfo].executable[DefaultInfo].files_to_run.executable.path

    linter_name = linter_exe.split("/")[-1]
    linter_config_opt = linter[LinterInfo].config_option
    if linter[LinterInfo].config != None:
        linter_config = linter[LinterInfo].config[DefaultInfo].files.to_list()
    else:
        linter_config = None
    linter_config_str = linter[LinterInfo].config_str

    if linter_config_opt and not linter_config:
        fail_msg = (
            "When specifying linter configuration for {}, ".format(linter_name) +
            "'config' must be specified if 'config_option' is set."
        )
        fail(msg=fail_msg)

    if linter_config_str and linter_config_opt:
        fail(msg="Don't both specify a config file option and raw string config")

    if linter_config_opt:
        configuration = " ".join(
            [
                "{} {}".format(linter_config_opt, shell.quote(config.path))
                for config in linter_config
            ],
        )
    elif linter_config_str:
        configuration = linter_config_str
    else:
        configuration = ""

    linter_inputs = src_files
    if linter_config:
        linter_inputs.extend(linter_config)

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

    tool_inputs, tool_input_manifests = ctx.resolve_tools(tools = [linter[LinterInfo].executable])

    ctx.actions.run(
        outputs = outputs + [report_out],
        inputs = linter_inputs,
        executable = linter_template_expanded_exe,
        tools = tool_inputs,
        arguments = pairs,
        mnemonic = "MirrorAndLint",
        use_default_shell_env = True,
        input_manifests = tool_input_manifests,
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
    linters_map = { lang: "@linting_system//:no-op" for lang in SUPPORTED_LANGUAGES }
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
                default = Label('@linting_system//:lint.sh.TEMPLATE'),
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
            '_ruby_linter' : attr.label(
                default = linters_map["ruby"],
            ),
            '_rust_linter' : attr.label(
                default = linters_map["rust"],
            ),
            '_cc_linter' : attr.label(
                default = linters_map["cc"],
            ),
        },
    )
