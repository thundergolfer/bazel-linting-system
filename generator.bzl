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

#    prefix = "{}/{}".format(ctx.label.package, ctx.label.name)
    # Note: Don't add ctx.label.package to prefix as it is implicitly added
    prefix = "__linting_rules/" + ctx.label.name

    suffix = "linted"
    outputs = []
    for f in src_files:
        declared_path = "{}/{}.{}".format(prefix, f.path, suffix)
        print(declared_path)
        o = ctx.actions.declare_file(declared_path)
        outputs.append(o)

    pairs = [
        "{};{}".format(left, right) for left, right in
        zip([f.path for f in src_files], [o.path for o in outputs])
    ]

    print(pairs)

    ctx.actions.run(
        outputs = outputs,
        inputs = src_files,
        executable = ctx.executable._mirror_sources,
        arguments = [
            suffix,
            "{}/{}".format(ctx.label.package, prefix)
        ] + pairs,
        mnemonic = "Copy",
        use_default_shell_env = True,
    )

#    copy_cmd = "cp {src} {out}".format(
#        src = shell.quote(src_files[0].path),
#        out = shell.quote(out.path),
#    )

    # TODO(Jonathon): Reinstate this
#    cmd = "{linter_exe} {config} {srcs} > {out}".format(
#        linter_exe = linter_exe,
#        config = configuration,
#        srcs = " ".join([
#            shell.quote("{}/{}".format(repo_root, src_f.path)) for
#            src_f in src_files
#        ]),
#        out = shell.quote(out.path),
#    )
#    debug("Running: \"{}\"".format(cmd))
#
#    progress_msg = "Linting with {linter}: {srcs}".format(
#        linter=linter_name,
#        srcs=" ".join([src_f.path for src_f in src_files])
#    )

    return [
        DefaultInfo(files = depset(outputs)),
        OutputGroupInfo(
            report = depset(outputs),
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
            '_mirror_sources' : attr.label(
                default = Label('@linting_rules//:mirror_sources'),
                executable = True,
                cfg = "host"
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