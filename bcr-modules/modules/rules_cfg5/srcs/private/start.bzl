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

"""This template creates a powershell script file that runs the CFG5 from the git repository and not the Bazle workspace repository."""
_CFG5_START_POWERSHELL_TEMPLATE = """
$ErrorActionPreference = "Stop"
$script_full_path = $PSCommandPath
$relative_path_to_run_files = "{script_short_path}"
$relative_path_to_ws_root = "{script_package_path}"
$cfg5_bin_path = "{cfg5_bin_path}"
$dpa_file_path = "{dpa_file_path}"
$additional_arguments = " {cfg5_args}"
$project_root_path = "{project_root_path}"


$dirCount_relative_path_to_run_files = ($relative_path_to_run_files -split '/' ).count - 1
$dirCount_relative_path_to_ws_package = 2
$dirCount_relative_path_to_ws_root = ($relative_path_to_ws_root -split '/' ).count - 1
# Relative directories + parent directory of script file
$dir_count_to_ws_root = $dirCount_relative_path_to_run_files + $dirCount_relative_path_to_ws_package + $dirCount_relative_path_to_ws_root + 1

$ws_root_path = $script_full_path
for ($i=0; $i -lt $dir_count_to_ws_root; $i++) {{
    $ws_root_path = Split-Path -Parent $ws_root_path
}}

$cfg5_abs_path = $ws_root_path + "/" + $cfg5_bin_path
$dpa_file_abs_path = $ws_root_path + "/" + $dpa_file_path
$cfg5_start_command = $cfg5_abs_path +" -p "+ $dpa_file_abs_path + $additional_arguments
Get-ChildItem -Path $ws_root_path/$project_root_path -Recurse | ForEach-Object {{ if ($_.PSIsContainer -eq $false -and $_.GetType().GetProperty('IsReadOnly')) {{ $_.IsReadOnly = $false }} }}
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "$cfg5_start_command" > cfg5_start.log
"""

# This template creates a batch file that serves as bootstrap for the powershell script to start CFG5 (and fork the process).
_CFG5_START_SCRIPT_WRAPPER_TEMPLATE = """
powershell.exe -NoProfile -File "{ps_start_script_path}"
"""

def _start_cfg5_windows_impl(ctx):
    info = ctx.toolchains["//rules/cfg5:toolchain_type"]

    cfg5_ps_script_file = ctx.actions.declare_file(ctx.label.name + ".ps1")
    powershell_command = _CFG5_START_POWERSHELL_TEMPLATE.format(
        script_short_path = cfg5_ps_script_file.short_path,
        script_package_path = cfg5_ps_script_file.path,
        cfg5_bin_path = info.cfg5_path.path,
        dpa_file_path = ctx.file.dpa.path,
        cfg5_args = ctx.attr.cfg5_args,
        project_root_path = ctx.file.dpa.dirname,
    ).strip()
    ctx.actions.write(cfg5_ps_script_file, powershell_command, is_executable = True)

    start_script_wrapper_file = ctx.actions.declare_file(ctx.label.name + ".bat")
    powershell_wrapper_script_command = _CFG5_START_SCRIPT_WRAPPER_TEMPLATE.format(
        ps_start_script_path = cfg5_ps_script_file.short_path,
    ).strip()
    ctx.actions.write(start_script_wrapper_file, powershell_wrapper_script_command, is_executable = True)

    return [
        DefaultInfo(
            executable = start_script_wrapper_file,
            runfiles = ctx.runfiles(files = [cfg5_ps_script_file]),
        ),
    ]

start_cfg5_windows = rule(
    implementation = _start_cfg5_windows_impl,
    attrs = {
        "dpa": attr.label(
            allow_single_file = [".dpa"],
            mandatory = True,
            doc = "The dpa file to start the CFG5 with",
        ),
        "cfg5_args": attr.string(
            mandatory = False,
            doc = "Additional CFG5 arguments",
        ),
    },
    executable = True,
    toolchains = ["//rules/cfg5:toolchain_type"],
)
