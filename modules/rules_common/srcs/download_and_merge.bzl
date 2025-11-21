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

"""This repository rule will download two packages and merge them"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "read_netrc", "read_user_netrc", "use_netrc")

DEFAULT_CANONICAL_ID_ENV = "BAZEL_HTTP_RULES_URLS_AS_DEFAULT_CANONICAL_ID"

_download_and_merge_attrs = {
    "url": attr.string(doc = "Url of the main package that the tool is merged into"),
    "prefix": attr.string(doc = "Optional strip_prefix value of the main package that the tool is merged into"),
    "sha": attr.string(doc = "sha of the main package that the tool is merged into"),
    "build_file": attr.label(
        allow_single_file = True,
        doc = "Optional build_file of the OS generic tool that should be merged into the main package",
    ),
    "build_file_linux": attr.label(
        allow_single_file = True,
        doc = "Optional build_file of the linux tool that should be merged into the main package",
    ),
    "build_file_windows": attr.label(
        allow_single_file = True,
        doc = "Optional build_file of the windows tool that should be merged into the main package",
    ),
    "extract_path": attr.string(doc = "Path to where the tool will be merged into the main package, relative from the main package path"),
    # The default use case without os differences
    "tool_url": attr.string(doc = "Optional url of the OS generic tool that should be merged into the main package"),
    "tool_prefix": attr.string(doc = "Optional strip_prefix of the OS generic tool that should be merged into the main package"),
    "tool_sha": attr.string(doc = "Optional sha value of the OS generic tool that should be merged into the main package"),
    # Windows settings
    "tool_url_windows": attr.string(doc = "Optional url of the windows tool that should be merged into the main package"),
    "tool_prefix_windows": attr.string(doc = "Optional strip_prefix value of the windows tool that should be merged into the main package"),
    "tool_sha_windows": attr.string(doc = "Optional sha value of the windows tool that should be merged into the main package"),
    # Linux settings
    "tool_url_linux": attr.string(doc = "Optional url of the linux tool that should be merged into the main package"),
    "tool_prefix_linux": attr.string(doc = "Optional strip_prefixvalue of the linux tool that should be merged into the main package"),
    "tool_sha_linux": attr.string(doc = "Optional sha value of the linux tool that should be merged into the main package"),
    "netrc": attr.string(
        doc = "Location of the .netrc file to use for authentication",
    ),
    "auth_patterns": attr.string_dict(doc = "Standard way of adding auth_patterns, see http_archive for the same setup"),
    "integrity": attr.string(doc = "This is the integrity string, will be updated automatically and cannot really be set for a rule downloading different packages depending on OS"),
}

def _get_auth(ctx, urls):
    """Given the list of URLs obtain the correct auth dict."""
    if ctx.attr.netrc:
        netrc = read_netrc(ctx, ctx.attr.netrc)
    elif "NETRC" in ctx.os.environ:
        netrc = read_netrc(ctx, ctx.os.environ["NETRC"])
    else:
        netrc = read_user_netrc(ctx)
    return use_netrc(netrc, urls, ctx.attr.auth_patterns)

def update_attrs(orig, keys, override):
    """Utility function for altering and adding the specified attributes to a particular repository rule invocation.

     This is used to make a rule reproducible.

    Args:
        orig: dict of actually set attributes (either explicitly or implicitly)
            by a particular rule invocation
        keys: complete set of attributes defined on this rule
        override: dict of attributes to override or add to orig

    Returns:
        dict of attributes with the keys from override inserted/updated
    """
    result = {}
    for key in keys:
        if getattr(orig, key) != None:
            result[key] = getattr(orig, key)
    result["name"] = orig.name
    result.update(override)
    return result

def _download_and_merge_impl(repository_ctx):
    auth = _get_auth(
        repository_ctx,
        [repository_ctx.attr.tool_url_linux, repository_ctx.attr.tool_url_windows, repository_ctx.attr.tool_url, repository_ctx.attr.url],
    )

    # Download first package
    download_info = repository_ctx.download_and_extract(
        [repository_ctx.attr.url],
        sha256 = repository_ctx.attr.sha,
        stripPrefix = repository_ctx.attr.prefix,
        auth = auth,
    )

    repository_ctx.delete(repository_ctx.attr.extract_path)

    if repository_ctx.attr.build_file_linux and repository_ctx.attr.build_file_windows:
        if repository_ctx.os.name == "linux":
            content = repository_ctx.read(repository_ctx.attr.build_file_linux)

        else:
            content = repository_ctx.read(repository_ctx.attr.build_file_windows)

        repository_ctx.file(
            "BUILD.bazel",
            content = content,
        )
    else:
        content = repository_ctx.read(repository_ctx.attr.build_file)

        repository_ctx.file(
            "BUILD.bazel",
            content = content,
        )

    if repository_ctx.attr.tool_url_windows and repository_ctx.attr.tool_url_linux:
        if repository_ctx.os.name == "linux":
            # Linux case
            # Download second package
            additional_download_info = repository_ctx.download_and_extract(
                [repository_ctx.attr.tool_url_linux],
                sha256 = repository_ctx.attr.tool_sha_linux,
                stripPrefix = repository_ctx.attr.tool_prefix_linux,
                output = repository_ctx.attr.extract_path,
                auth = auth,
            )
        else:
            # Windows case
            # Download second package
            additional_download_info = repository_ctx.download_and_extract(
                [repository_ctx.attr.tool_url_windows],
                sha256 = repository_ctx.attr.tool_sha_windows,
                stripPrefix = repository_ctx.attr.tool_prefix_windows,
                output = repository_ctx.attr.extract_path,
                auth = auth,
            )

    else:
        # Download second package
        additional_download_info = repository_ctx.download_and_extract(
            [repository_ctx.attr.tool_url],
            sha256 = repository_ctx.attr.tool_sha,
            stripPrefix = repository_ctx.attr.tool_prefix,
            output = repository_ctx.attr.extract_path,
            auth = auth,
        )

    integrity_override = {"integrity": download_info.integrity + additional_download_info.integrity}
    return update_attrs(repository_ctx.attr, _download_and_merge_attrs.keys(), integrity_override)

# Define the repository rule
download_and_merge = repository_rule(
    implementation = _download_and_merge_impl,
    attrs = _download_and_merge_attrs,
    doc = "This rule will download a main package and merge a tool package into it and then put everything into a singular external package. One can either add an OS generic tool config for the tool that is merged into the main package or use the OS specific attrs to manage both windows and linux",
    environ = [DEFAULT_CANONICAL_ID_ENV],
)
