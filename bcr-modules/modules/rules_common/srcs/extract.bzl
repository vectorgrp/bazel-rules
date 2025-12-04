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

"""Rule to extract archives and add their content as output"""

def _extract_zip_impl(ctx):
    ctx.actions.run(
        mnemonic = "extractarchiveunzip",
        executable = ctx.executable.unzip_executable,
        outputs = ctx.outputs.extracted_files,
        inputs = [ctx.file.archive],
        arguments = ["-o", ctx.file.archive.path, "-d", ctx.outputs.extracted_files[0].root.path + "/" + ctx.label.package + "/" + ctx.label.name],
    )

    return [
        DefaultInfo(files = depset(ctx.outputs.extracted_files)),
    ]

def _extract_archive_attrs(file_extensions):
    return {
        "options": attr.string(doc = "Options to give to the extraction tool", mandatory = False),
        "archive": attr.label(
            doc = "Archives to extract their contents from",
            mandatory = True,
            allow_single_file = file_extensions,
        ),
        "extracted_files": attr.output_list(allow_empty = False, doc = "Extracted files list from the given archives", mandatory = True),
        "unzip_executable": attr.label(executable = True, allow_single_file = True, cfg = "exec", default = Label("@ape//ape:unzip")),
    }

extract_doc = """
Extract Archive: 
- Toolchains: extract_toolchain for the given type of archive
- Inputs: An archive in any of the allowed formats
- Outputs: Any of the contained files in a List 
- Actions: One extraction action calling the extract tool with the given parameters
"""

extract_zip_def = rule(implementation = _extract_zip_impl, attrs = _extract_archive_attrs([".zip"]), doc = extract_doc)

def extract_zip(name, **kwargs):
    """Wraps the extract_zip with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        **kwargs: All of the attrs of the extract_zip rule

    Returns:
        A extract_zip_def rule that contains the actual implementation
    """
    extract_zip_def(
        name = name,
        **kwargs
    )
