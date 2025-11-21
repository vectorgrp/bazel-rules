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

"""This repository rule will merge two packages together. The buildfile and the second package is configurable for linux and windows."""

def _merge_packages_impl(repository_ctx):
    # Check the OS and set the second package and the build file
    if "linux" in repository_ctx.os.name:
        second_package = repository_ctx.path(repository_ctx.attr.second_package_linux)
        build_file = repository_ctx.read(repository_ctx.attr.build_file_linux)
    elif "windows" in repository_ctx.os.name:
        second_package = repository_ctx.path(repository_ctx.attr.second_package_windows)
        build_file = repository_ctx.read(repository_ctx.attr.build_file_windows)
    else:
        fail("Unsupported platform: {}".format(repository_ctx.os.name))

    # Activate watch to detect changes
    repository_ctx.watch_tree(second_package)
    repository_ctx.watch_tree(repository_ctx.attr.main_package)

    # Link everything of the main package into the new repo
    main_package_file_list = repository_ctx.path(repository_ctx.attr.main_package).readdir()
    for file in main_package_file_list:
        repository_ctx.symlink(file, file.basename)

    # Link second package into the new repo
    repository_ctx.symlink(second_package, repository_ctx.attr.second_package_extraction_dir)

    # Create the BUILD file for the new repository
    repository_ctx.file(
        "BUILD.bazel",
        content = build_file,
    )

merge_packages = repository_rule(
    implementation = _merge_packages_impl,
    attrs = {
        "main_package": attr.label(
            mandatory = True,
            doc = "The main package to which the secondary package will be linked.",
        ),
        "second_package_linux": attr.label(doc = "The secondary package for Linux that will be linked to the main package."),
        "second_package_windows": attr.label(doc = "The secondary package for Windows that will be linked to the main package."),
        "second_package_extraction_dir": attr.string(
            mandatory = True,
            doc = "The directory where symlinks for the secondary package will be created relative to the main package.",
        ),
        "build_file_linux": attr.label(
            allow_single_file = True,
            doc = "Build file for Linux",
        ),
        "build_file_windows": attr.label(
            allow_single_file = True,
            doc = "Build file for Windows",
        ),
    },
    doc = "This rule creates symlinks between a secondary package (configureable for Linux and Windows) and a main package.",
)
