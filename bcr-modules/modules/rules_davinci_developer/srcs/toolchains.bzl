# MIT License

# Copyright (c) 2025 Vector Group

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""Toolchain for davinci_developer with support for dvimex and dvswcgen binaries"""

def _davinci_developer_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        # Paths (used on Windows)
        dvimex_path = ctx.attr.dvimex_path,
        dvswcgen_path = ctx.attr.dvswcgen_path,
        davincidev_path = ctx.attr.davincidev_path,
        # Labels (used on Linux)
        dvimex_label = ctx.executable.dvimex_label,
        dvswcgen_label = ctx.executable.dvswcgen_label,
        # Legacy
        davinci_developer_cmd_label = ctx.executable.davinci_developer_cmd_label,
    )
    return [toolchain_info]

davinci_developer_toolchain = rule(
    implementation = _davinci_developer_toolchain_impl,
    attrs = {
        # Executable labels
        "dvimex_label": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Label pointing to the dvimex binary",
        ),
        "dvswcgen_label": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Label pointing to the dvswcgen binary",
        ),
        # System paths
        "dvimex_path": attr.string(
            mandatory = False,
            doc = "System path to the dvimex binary",
        ),
        "dvswcgen_path": attr.string(
            mandatory = False,
            doc = "System path to the dvswcgen binary",
        ),
        # Windows Gui
        "davincidev_path": attr.string(
            mandatory = False,
            doc = "System path to the DaVinciDEV.exe to start the GUI via Bazel.",
        ),
        # Legacy
        "davinci_developer_cmd_label": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Label version of the developer cmd that can be used if the DaVinci developer was downloaded via bazel, only used for linux",
        ),
    },
    doc = """
Provides access to DaVinci Developer binaries via path or label.
Used by rules to determine which binary to execute based on platform and rule configuration.
""",
)
