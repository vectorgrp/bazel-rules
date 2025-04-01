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
