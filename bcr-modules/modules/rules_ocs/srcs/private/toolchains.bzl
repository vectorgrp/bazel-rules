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
