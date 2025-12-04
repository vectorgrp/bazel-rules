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

"""Rule to run DaVinci Developer directly with a provided .dcf file and input dependencies."""

# --- Windows and Linux execution templates ---
_DAVINCI_COMMAND_TEMPLATE_WINDOWS = """
$ErrorActionPreference = 'Stop'
start-process -PassThru -NoNewWindow -RedirectStandardOutput {log_path} -Wait '{binary_path}' -ArgumentList '{full_args}'
"""

_DAVINCI_COMMAND_TEMPLATE_LINUX = """
{binary_path} {full_args} > {log_path} 2>&1
"""

# --- Core function to run the Developer tool ---
def _run_davinci_developer(ctx, inputs):
    info = ctx.toolchains["@rules_davinci_developer//:toolchain_type"]
    log_file = ctx.actions.declare_file(ctx.label.name + "/dv.log")

    # Start with base argument: -d <dcf_file>
    full_args = "-d {}".format(ctx.file.dcf_file.path)

    # Add -ef <export_output> if present
    output_files = [log_file]
    if ctx.outputs.export_output:
        full_args += " -ef {}".format(ctx.outputs.export_output.path)
        output_files.append(ctx.outputs.export_output)

    # Append additional CLI arguments from genargs (e.g. -x)
    if ctx.attr.genargs:
        full_args += " " + " ".join(ctx.attr.genargs)

    # --- Select the appropriate binary based on chosen binary_name ---
    binary_name = ctx.attr.binary_name
    if binary_name == "dvimex":
        binary_path = info.dvimex_path
        binary_label = info.dvimex_label
    elif binary_name == "dvswcgen":
        binary_path = info.dvswcgen_path
        binary_label = info.dvswcgen_label
    else:
        fail("Invalid binary_name '{}'. Must be 'dvimex' or 'dvswcgen'.".format(binary_name))

    # Run on Windows
    if ctx.attr.private_is_windows:
        ctx.actions.run(
            mnemonic = "daVinciDeveloper",
            executable = "powershell.exe",
            inputs = inputs + [ctx.file.dcf_file],
            outputs = output_files,
            arguments = ["-NoProfile", _DAVINCI_COMMAND_TEMPLATE_WINDOWS.format(
                binary_path = binary_path,
                full_args = full_args,
                log_path = log_file.path,
            )],
            env = {
                "OS": "Windows_NT",
                "windir": "C:\\Windows",
                "SystemRoot": "C:\\Windows",
            },
        )
        # Run on Linux

    else:
        ctx.actions.run_shell(
            mnemonic = "daVinciDeveloper",
            tools = [binary_label] if binary_label else [],
            inputs = inputs + [ctx.file.dcf_file],
            outputs = output_files,
            command = _DAVINCI_COMMAND_TEMPLATE_LINUX.format(
                binary_path = binary_label.path,
                full_args = full_args,
                log_path = log_file.path,
            ),
        )

    return [
        DefaultInfo(files = depset(output_files)),
    ]

# --- Rule implementation ---
def _developer_run_impl(ctx):
    inputs = list(ctx.files.inputs)
    return _run_davinci_developer(ctx, inputs)

# --- Rule attributes ---
developer_rule_attrs = {
    "dcf_file": attr.label(
        allow_single_file = [".dcf"],
        mandatory = True,
        doc = "The main .dcf file passed to DaVinci Developer via -d",
    ),
    "genargs": attr.string_list(
        doc = "Additional CLI arguments passed after -d <dcf_file>. `-ef` is added automatically if export_output is set.",
    ),
    "inputs": attr.label_list(
        allow_files = True,
        doc = "Other input files (e.g. model files) needed by DaVinci Developer",
    ),
    "export_output": attr.output(
        doc = "ARXML output file passed to DaVinci Developer via -ef (automatically included)",
    ),
    "binary_name": attr.string(
        mandatory = True,
        values = ["dvimex", "dvswcgen"],
        doc = "Which binary to use from the toolchain. One of 'dvimex' or 'dvswcgen'.",
    ),
    "private_is_windows": attr.bool(
        mandatory = True,
        doc = "Set internally to indicate platform (via select)",
    ),
}

# --- Define the rule ---
developer_run_def = rule(
    implementation = _developer_run_impl,
    attrs = developer_rule_attrs,
    toolchains = ["@rules_davinci_developer//:toolchain_type"],
    doc = """
Runs DaVinci Developer using the specified .dcf file.
Pass input files as `inputs`, CLI args via `genargs` (excluding -d/-ef),
and use `export_output` to declare the ARXML output file.
Select the binary via `binary_name` (either 'dvimex' or 'dvswcgen').
""",
)

# --- Wrapper to auto-set platform ---
def developer_run(name, **kwargs):
    developer_run_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

####################################
# Start DaVinci Developer with Bazel
####################################

#This template creates a powershell script file that runs the DaVinci Developer from the git repository and not the Bazle workspace repository.
_DEVELOPER_START_POWERSHELL_TEMPLATE = """
$ErrorActionPreference = "Stop"
$script_full_path = $PSCommandPath
$relative_path_to_run_files = "{script_short_path}"
$relative_path_to_ws_root = "{script_package_path}"
$developer_bin_path = "{developer_bin_path}"
$dcf_file_path = "{dcf_file_path}"
$additional_arguments = " {developer_args}"
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

$developer_abs_path = $developer_bin_path
$dcf_file_abs_path = $ws_root_path + "/" + $dcf_file_path
$developer_start_command = $developer_abs_path +" -d "+ $dcf_file_abs_path + $additional_arguments
Get-ChildItem -Path $ws_root_path/$project_root_path -Recurse | ForEach-Object {{ if ($_.PSIsContainer -eq $false -and $_.GetType().GetProperty('IsReadOnly')) {{ $_.IsReadOnly = $false }} }}
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "$developer_start_command" > developer/start.log
"""

# This template creates a batch file that serves as bootstrap for the powershell script to start DaVinci Developer (and fork the process).
_DEVELOPER_START_SCRIPT_WRAPPER_TEMPLATE = """
powershell.exe -File "{ps_start_script_path}"
"""

def _start_developer_windows_impl(ctx):
    info = ctx.toolchains["@rules_davinci_developer//:toolchain_type"]

    developer_ps_script_file = ctx.actions.declare_file(ctx.label.name + ".ps1")
    powershell_command = _DEVELOPER_START_POWERSHELL_TEMPLATE.format(
        script_short_path = developer_ps_script_file.short_path,
        script_package_path = developer_ps_script_file.path,
        developer_bin_path = info.davincidev_path,
        dcf_file_path = ctx.file.dcf.path,
        developer_args = ctx.attr.developer_args,
        project_root_path = ctx.file.dcf.dirname,
    ).strip()
    ctx.actions.write(developer_ps_script_file, powershell_command, is_executable = True)

    start_script_wrapper_file = ctx.actions.declare_file(ctx.label.name + ".bat")
    powershell_wrapper_script_command = _DEVELOPER_START_SCRIPT_WRAPPER_TEMPLATE.format(
        ps_start_script_path = developer_ps_script_file.short_path,
    ).strip()
    ctx.actions.write(start_script_wrapper_file, powershell_wrapper_script_command, is_executable = True)

    return [
        DefaultInfo(
            executable = start_script_wrapper_file,
            runfiles = ctx.runfiles(files = [developer_ps_script_file, ctx.file.model]),
        ),
    ]

start_developer_windows = rule(
    implementation = _start_developer_windows_impl,
    attrs = {
        "dcf": attr.label(
            allow_single_file = [".dcf"],
            mandatory = True,
            doc = "The dcf file to start the DaVinci Developer with",
        ),
        "developer_args": attr.string(
            mandatory = False,
            doc = "Additional DaVinci Developer arguments",
        ),
        "model": attr.label(
            allow_single_file = [".arxml"],
            mandatory = True,
            doc = "The model that is referenced by the dcf file",
        ),
    },
    executable = True,
    toolchains = ["@rules_davinci_developer//:toolchain_type"],
)
