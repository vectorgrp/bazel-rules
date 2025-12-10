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

"""This is a common function for any rule needing to copy files around """

def _copy_bash(ctx, src, dst):
    if hasattr(src, "path"):
        ctx.actions.run_shell(
            inputs = [src],
            outputs = [dst],
            command = "cp -f \"$1\" \"$2\"",
            arguments = [src.path, dst.path],
            mnemonic = "CopyFile",
            progress_message = "Copying files",
        )
    else:
        fail("The provided src is not a File!")

def _copy_cmd(ctx, src, dst):
    if hasattr(src, "path"):
        full_name = src.path.replace("/", "") + src.basename
        bat = ctx.actions.declare_file("copy_file/" + ctx.label.name + full_name + "-cmd.bat")
        ctx.actions.write(
            output = bat,
            content = "@copy /Y \"%s\" \"%s\" >NUL" % (
                src.path.replace("/", "\\"),
                dst.path.replace("/", "\\"),
            ),
            is_executable = True,
        )
        ctx.actions.run(
            inputs = [src, bat],
            outputs = [dst],
            executable = "cmd.exe",
            arguments = ["/C", bat.path.replace("/", "\\")],
            mnemonic = "CopyFile",
            progress_message = "Copying files",
        )
    else:
        fail("The provided src is not a File!")

def copy_file(ctx, src, dst, is_windows):
    if is_windows:
        _copy_cmd(ctx, src, dst)
    else:
        _copy_bash(ctx, src, dst)
