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

"""Toolchain for davinci_developer"""

def _davinci_developer_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        davinci_developer_label = ctx.executable.davinci_developer_label,
        davinci_developer_path = ctx.attr.davinci_developer_path,
        davinci_developer_cmd_label = ctx.executable.davinci_developer_cmd_label,
    )
    return [toolchain_info]

davinci_developer_toolchain = rule(
    implementation = _davinci_developer_toolchain_impl,
    attrs = {
        "davinci_developer_label": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Label version of the developer path that can be used if the DaVinci developer was downloaded via bazel, mostly used for linux",
        ),
        "davinci_developer_path": attr.string(mandatory = False, doc = "Path version of the developer path that can be used if the DaVinci developer was not downloaded via bazel and is installed system wide, mostly used for windows"),
        "davinci_developer_cmd_label": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Label version of the developer cmd that can be used if the DaVinci developer was downloaded via bazel, only used for linux",
        ),
    },
    doc = """Either davinci_developer_label or davinci_developer_path have to be set for the toolchain to have any effect. This will then make the DaVinci Developer available via toolchain for rules like dvteam""",
)