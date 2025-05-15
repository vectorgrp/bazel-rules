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

"""Toolchain for gradle"""

def _gradle_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        gradle_label = ctx.executable.gradle_label,
        gradle_path = ctx.attr.gradle_path,
        gradle_properties = ctx.file.gradle_properties,
    )
    return [toolchain_info]

gradle_toolchain = rule(
    implementation = _gradle_toolchain_impl,
    attrs = {
        "gradle_label": attr.label(
            mandatory = False,
            allow_single_file = True,
            cfg = "exec",
            executable = True,
            doc = "Optional label version of the gradle path, usually used when gradle is downloaded as an external package with bazel",
        ),
        "gradle_path": attr.string(
            mandatory = False,
            doc = "Optional path version of the gradle path, usually used when gradle is NOT downloaded as an external package with bazel",
        ),
        "gradle_properties": attr.label(mandatory = False, allow_single_file = True, executable = False, doc = "optional gradle properties to use other than the default system one"),
    },
    doc = "Simple gradle toolchain that is used for DaVinciTeam rules and others that rely on gradle",
)
