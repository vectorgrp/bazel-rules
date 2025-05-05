"""Toolchain for 7z"""

def _seven_zip_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        sevenzip_dir = ctx.attr.sevenzip_dir,
    )
    return [toolchain_info]

seven_zip_toolchain = rule(
    implementation = _seven_zip_toolchain_impl,
    attrs = {
        "sevenzip_dir": attr.string(default = "C:\\Program Files\\7-Zip", mandatory = False, doc = "directory containing local 7z.exe under windows"),
    },
    doc = """When running under windows, set the directory containing the local 7z.exe. Default is C:\\Program Files\\7-Zip. Not needed for linux.""",
)
