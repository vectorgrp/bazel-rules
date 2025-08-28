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

"""This repository rule will add the .netrc information to a freshly generated gradle.properties file for later use by other tools"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "read_netrc", "read_user_netrc")

def _get_netrc_token(ctx, url):
    """Given the list of URLs obtain the correct auth dict."""
    if ctx.attr.netrc:
        netrc = read_netrc(ctx, ctx.attr.netrc)
    elif "NETRC" in ctx.os.environ:
        netrc = read_netrc(ctx, ctx.os.environ["NETRC"])
    else:
        netrc = read_user_netrc(ctx)
    return netrc[url]["password"]

def _generate_gradle_properties_impl(repository_ctx):
    auth_tokens = repository_ctx.attr.gradle_properties_content

    for token in repository_ctx.attr.tokens:
        auth = _get_netrc_token(
            repository_ctx,
            repository_ctx.attr.tokens[token],
        )
        auth_tokens += token + "=" + auth + "\n"

    repository_ctx.file("gradle.properties", auth_tokens)

    repository_ctx.file(
        "BUILD.bazel",
        """
package(default_visibility = ["//visibility:public"])

exports_files(glob(["**/*"]))

filegroup(
    name = "package",
    srcs = glob([
        "**/*",
    ]),
)

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)
""",
    )

# Define the repository rule
generate_gradle_properties = repository_rule(
    implementation = _generate_gradle_properties_impl,
    attrs = {
        "netrc": attr.string(
            doc = "Location of the .netrc file to use for authentication",
            mandatory = False,
        ),
        "tokens": attr.string_dict(
            doc = "Map between tokens to generate and their respective url in the .netrc file",
            mandatory = True,
        ),
        "gradle_properties_content": attr.string(
            default = "",
            doc = "The content of the gradle.properties file before the tokens are added to it",
            mandatory = False,
        ),
    },
    local = True,
)
