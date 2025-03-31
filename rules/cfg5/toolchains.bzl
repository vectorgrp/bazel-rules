"""Toolchain for CFG5 """

def _cfg5_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        cfg5_path = ctx.executable.cfg5_path,
        cfg5_files = ctx.files.cfg5_files,
        cfg5cli_path = ctx.executable.cfg5cli_path,
    )
    return [toolchain_info]

cfg5_toolchain = rule(
    implementation = _cfg5_toolchain_impl,
    attrs = {
        "cfg5_path": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Path to the Cfg5 used in the bazel rules",
        ),
        "cfg5_files": attr.label(mandatory = False, doc = "Optional cfg5 files used as input for hermiticity"),
        "cfg5cli_path": attr.label(
            mandatory = True,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Mandatory path to the Cfg5 cli path used in the bazel rules",
        ),
    },
)
