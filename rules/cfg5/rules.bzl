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

"""Rules for cfg5"""

load("//rules/common:create_davinci_tool_workspace.bzl", "create_davinci_tool_workspace")
#load("//rules/vtt:toolchains.bzl", "generate_tools_vtt")

_CFG5_GENERATE_TEMPLATE_WINDOWS = """
start-process -WorkingDirectory  {dpa_folder} -PassThru -NoNewWindow -RedirectStandardOutput {dpa_folder}/daVinciCfg5.log -Wait {cfg5cli_path} -ArgumentList '-p {dpa_path} -g {genargs} --verbose'
"""
_CFG5_GENERATE_TEMPLATE_WINDOWS_WORKSPACE = """
$folderPath = '{dpa_folder}'
Get-ChildItem -Path $folderPath -Recurse -File | ForEach-Object {{ $_.IsReadOnly = $false; $_.Attributes = 'Normal'}}
start-process -WorkingDirectory  {dpa_folder} -PassThru -NoNewWindow -RedirectStandardOutput {dpa_folder}/daVinciCfg5.log -Wait {cfg5cli_path} -ArgumentList '-p {dpa_path} -g {genargs} --verbose'
"""

_CFG5_GENERATE_TEMPLATE_LINUX = """
{cfg5cli_path} -p  {dpa_path} -g {genargs} --verbose > {dpa_folder}/daVinciCfg5.log
"""
_CFG5_GENERATE_TEMPLATE_LINUX_WORKSPACE = """
sudo chmod -R 777 {dpa_folder} &&
{cfg5cli_path} -p  {dpa_folder}/{dpa_path} -g {genargs} --verbose > {dpa_folder}/daVinciCfg5.log
"""

def _cfg5_generate(ctx, dpa_path, dpa_folder, dpa_file, inputs, template, is_workspace, additional_genargs, tools = []):
    info = ctx.toolchains["//rules/cfg5:toolchain_type"]

    hdrs = []
    for f in ctx.outputs.generated_files:
        if f.extension == "h":
            hdrs.append(f)

    compilation_context = cc_common.create_compilation_context(
        headers = depset(
            hdrs,
        ),
    )

    dvcfg5_report_file_name = "DVCfg5ReportFile.xml"
    dvcfg5_report_file = ctx.actions.declare_file(dvcfg5_report_file_name)

    if "/" in dpa_folder:
        dvcfg5_log_file_name = dpa_folder.split("/")[-1] + "/daVinciCfg5.log"
    else:
        dvcfg5_log_file_name = dpa_folder + "/daVinciCfg5.log"
    dvcfg5_log_file = ctx.actions.declare_file(dvcfg5_log_file_name)

    generate_tools = list(tools)

    if info.cfg5_files:
        generate_tools.extend(info.cfg5_files)
    else:
        generate_tools.append(info.cfg5cli_path)

    if ctx.attr.private_is_windows:
        upward_path = "../" * len(dpa_file.dirname.split("/"))
        report_file_path = "../" + dvcfg5_report_file.basename if is_workspace else upward_path + dvcfg5_report_file.path
        command = template.format(
            dpa_path = dpa_path,
            dpa_folder = dpa_folder,
            cfg5cli_path = info.cfg5cli_path.path,
            genargs = " ".join(ctx.attr.genArgs + ["--reportFile=" + report_file_path, "--reportArgs=CreateXmlFile"] + additional_genargs),
        )

        ctx.actions.run(
            mnemonic = "cfg5generate",
            executable = "powershell.exe",
            tools = generate_tools,
            inputs = inputs,
            outputs = ctx.outputs.generated_files + [dvcfg5_report_file, dvcfg5_log_file],
            arguments = [command],
            env =
                {"OS": "Windows_NT", "windir": "C:\\Windows", "SystemRoot": "C:\\Windows"},
        )

        return [
            DefaultInfo(files = depset(ctx.outputs.generated_files)),
            CcInfo(compilation_context = compilation_context),
        ]
    else:
        command = template.format(
            dpa_path = dpa_path,
            dpa_folder = dpa_folder,
            cfg5cli_path = info.cfg5cli_path.path,
            genargs = " ".join(ctx.attr.genArgs + ["--reportFile=" + dvcfg5_report_file.path, "--reportArgs=CreateXmlFile"] + additional_genargs),
        )

        ctx.actions.run_shell(
            mnemonic = "cfg5generate",
            tools = generate_tools,
            inputs = inputs,
            outputs = ctx.outputs.generated_files + [dvcfg5_report_file, dvcfg5_log_file],
            command = command,
        )

        return [
            DefaultInfo(files = depset(ctx.outputs.generated_files)),
            CcInfo(compilation_context = compilation_context),
        ]

def _cfg5_generate_workspace_impl(ctx, additional_genargs, tools = []):
    _cfg_workspace = create_davinci_tool_workspace(ctx, workspace_name = ctx.label.name + "_cfg_workspace", addtional_workspace_files = [ctx.file.dpa_file], is_windows = ctx.attr.private_is_windows, config_files = ctx.files.config_files, config_folders = ctx.attr.config_folders)

    dpa_copy = _cfg_workspace.addtional_workspace_files[0]
    dpa_path = dpa_copy.basename
    dpa_folder = dpa_copy.dirname
    inputs = _cfg_workspace.files + _cfg_workspace.addtional_workspace_files
    template = _CFG5_GENERATE_TEMPLATE_LINUX_WORKSPACE
    if ctx.attr.private_is_windows:
        template = _CFG5_GENERATE_TEMPLATE_WINDOWS_WORKSPACE

    if ctx.attr.sip:
        inputs.extend(ctx.attr.sip.files.to_list())
    return _cfg5_generate(ctx, dpa_path, dpa_folder, dpa_copy, inputs, template, True, additional_genargs, tools)

# def _cfg5_generate_vtt_workspace_impl(ctx):
    # tools = generate_tools_vtt(ctx)
    # return _cfg5_generate_workspace_impl(ctx, ["--genType=VTT", "--buildVTTProject"], tools)

cfg5_generate_workspace_attrs = {
    "dpa_file": attr.label(allow_single_file = [".dpa"], doc = "Dpa project file to start the cfg5 with"),
    "generated_files": attr.output_list(doc = "List of generated files that are added to the output"),
    "config_files": attr.label_list(allow_files = True, doc = "Additional configuration files to start the cfg5 with"),
    "genArgs": attr.string_list(doc = "The DaVinciCfgCmd argument options."),
    "sip": attr.label(doc = "sip location to mark it as a dependency, as it the sip is needed for cfg5 execution"),
    "private_is_windows": attr.bool(mandatory = True, doc = "Is set automatically to the correct OS value"),
    "config_folders": attr.string_list(doc = "(Optional) List of config folders that the path will be checked for in each file to create a nested Config folder structure, default is [\"Config\"]", default = ["Config"]),
}

# cfg5_generate_vtt_workspace_def = rule(
#     implementation = _cfg5_generate_vtt_workspace_impl,
#     attrs = cfg5_generate_workspace_attrs,
#     doc = """
# Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
# This rule is wrapped with private_is_windows attribute to separate between OS differences.
# Used specifically for the vtt use case, as this adds the correct vtt flags to the Cfg5 call automatically.
# """,
#     toolchains = ["//rules/cfg5:toolchain_type", "//rules/vtt:toolchain_type"],
# )

# def cfg5_generate_vtt_workspace(name, **kwargs):
#     """Wraps the cfg5_generate_vtt_workspace with the private_is_windows select statement in place

#     Args:
#         name: The unique name of this target
#         **kwargs: All of the attrs of the cfg5_generate_vtt_workspace rule

#     Returns:
#         A cfg5_generate_vtt_workspace_def rule that contains the actual implementation
#     """
#     cfg5_generate_vtt_workspace_def(
#         name = name,
#         private_is_windows = select({
#             "@bazel_tools//src/conditions:host_windows": True,
#             "//conditions:default": False,
#         }),
#         **kwargs
#     )

def _cfg5_generate_rt_workspace_impl(ctx):
    return _cfg5_generate_workspace_impl(ctx, ["--genType=REAL"])

cfg5_generate_rt_workspace_def = rule(
    implementation = _cfg5_generate_rt_workspace_impl,
    attrs = cfg5_generate_workspace_attrs,
    doc = """
Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
Used specifically for the rt use case, as this adds the correct rt flags to the Cfg5 call automatically.
""",
    toolchains = ["//rules/cfg5:toolchain_type"],
)

def cfg5_generate_rt_workspace(name, **kwargs):
    """Wraps the cfg5_generate_rt_workspace with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        **kwargs: All of the attrs of the cfg5_generate_rt_workspace rule

    Returns:
        A cfg5_generate_rt_workspace_def rule that contains the actual implementation
    """
    cfg5_generate_rt_workspace_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

# def _cfg5_generate_vtt_impl(ctx):
#     info_vtt = ctx.toolchains["//rules/vtt:toolchain_type"]

#     if not ctx.attr.private_is_windows and not info_vtt.vtt_cmd_path and not info_vtt.vtt_cmd_label:
#         fail("vttcmd_path is not set in the 'vtt_toolchain', but is necessary for the generation under Linux.")
#     inputs = depset(ctx.files.input_arxmls, transitive = [ctx.attr.dpa_linux.files])
#     dpa_path = ctx.file.dpa_windows.basename
#     dpa_folder = ctx.file.dpa_windows.dirname
#     dpa_file = ctx.file.dpa_linux
#     template = _CFG5_GENERATE_TEMPLATE_LINUX
#     if ctx.attr.private_is_windows:
#         dpa_file = ctx.file.dpa_windows
#         template = _CFG5_GENERATE_TEMPLATE_WINDOWS

#     tools = generate_tools_vtt(ctx)

#     return _cfg5_generate(ctx, dpa_path, dpa_folder, dpa_file, inputs, template, False, ["--genType=VTT", "--buildVTTProject"], tools)

def _cfg5_generate_rt_impl(ctx):
    inputs = depset(ctx.files.input_arxmls, transitive = [ctx.attr.dpa_linux.files])
    dpa_path = ctx.file.dpa_windows.basename
    dpa_folder = ctx.file.dpa_windows.dirname
    dpa_file = ctx.file.dpa_linux
    template = _CFG5_GENERATE_TEMPLATE_LINUX
    if ctx.attr.private_is_windows:
        dpa_file = ctx.file.dpa_windows
        template = _CFG5_GENERATE_TEMPLATE_WINDOWS

    return _cfg5_generate(ctx, dpa_path, dpa_folder, dpa_file, inputs, template, False, ["--genType=REAL"])

cfg5_generate_attrs = {
    "dpa_windows": attr.label(allow_single_file = [".dpa"], doc = "Dpa file for the windows execution of the cfg5"),
    "dpa_linux": attr.label(allow_single_file = [".dpa"], doc = "Dpa file for the linux execution of the cfg5"),
    "generated_files": attr.output_list(doc = "List of generated files that are added to the output"),
    "input_arxmls": attr.label_list(allow_files = [".arxml"], doc = "List of arxml files to use a input for the cfg5"),
    "genArgs": attr.string_list(doc = "The DaVinciCfgCmd argument options."),
    "private_is_windows": attr.bool(mandatory = True, doc = "Set automatically to the correct OS value"),
}

# cfg5_generate_vtt_def = rule(
#     implementation = _cfg5_generate_vtt_impl,
#     attrs = cfg5_generate_attrs,
#     doc = """
# Run the cfg5 directly in the project.
# This rule is wrapped with private_is_windows attribute to separate between OS differences.
# Used specifically for the vtt use case, as this adds the correct vtt flags to the Cfg5 call automatically.
# """,
#     toolchains = ["//rules/cfg5:toolchain_type", "//rules/vtt:toolchain_type"],
# )

# def cfg5_generate_vtt(name, **kwargs):
#     """Wraps the cfg5_generate_vtt with the private_is_windows select statement in place

#     Args:
#         name: The unique name of this target
#         **kwargs: All of the attrs of the cfg5_generate_vtt rule

#     Returns:
#         A cfg5_generate_vtt_def rule that contains the actual implementation
#     """
#     cfg5_generate_vtt_def(
#         name = name,
#         private_is_windows = select({
#             "@bazel_tools//src/conditions:host_windows": True,
#             "//conditions:default": False,
#         }),
#         **kwargs
#     )

cfg5_generate_rt_def = rule(
    implementation = _cfg5_generate_rt_impl,
    attrs = cfg5_generate_attrs,
    doc = """Run the cfg5 directly in the project.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
Used specifically for the rt use case, as this adds the correct rt flags to the Cfg5 call automatically.
""",
    toolchains = ["//rules/cfg5:toolchain_type"],
)

def cfg5_generate_rt(name, **kwargs):
    """Wraps the cfg5_generate_rt with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        **kwargs: All of the attrs of the cfg5_generate_rt rule

    Returns:
        A cfg5_generate_rt_workspace_def rule that contains the actual implementation
    """
    cfg5_generate_rt_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

#This template creates a powershell script file that runs the CFG5 from the git repository and not the Bazel workspace repository.
_CFG5_START_POWERSHELL_TEMPLATE = """
$ErrorActionPreference = "Stop"
$script_full_path = $PSCommandPath
$relative_path_to_run_files = "{script_short_path}"
$relative_path_to_ws_root = "{script_package_path}"
$cfg5_bin_path = "{cfg5_bin_path}"
$dpa_file_path = "{dpa_file_path}"
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

# Additional arguments need to be resolved after ws_root_path declaration, so that the variable is resolved in case a script is specified
$additional_arguments = " {cfg5_args}"

$cfg5_abs_path = $ws_root_path + "/" + $cfg5_bin_path
$dpa_file_abs_path = $ws_root_path + "/" + $dpa_file_path
$cfg5_start_command = $cfg5_abs_path +" -p "+ $dpa_file_abs_path + $additional_arguments
Get-ChildItem -Path $ws_root_path/$project_root_path -Recurse | ForEach-Object {{ if ($_.PSIsContainer -eq $false -and $_.GetType().GetProperty('IsReadOnly')) {{ $_.IsReadOnly = $false }} }}
Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "$cfg5_start_command" > cfg5_start.log
"""

# This template creates a batch file that serves as bootstrap for the powershell script to start CFG5 (and fork the process).
_CFG5_START_SCRIPT_WRAPPER_TEMPLATE = """
powershell.exe -File "{ps_start_script_path}"
"""

def _start_cfg5_windows_impl(ctx):
    info = ctx.toolchains["//rules/cfg5:toolchain_type"]
    runfiles = [ctx.file.dpa] + ctx.files.config_files

    cfg5_args = ctx.attr.cfg5_args
    if (ctx.file.script):
        runfiles.append(ctx.file.script)

        # The $ws_root_path is replaces within the ps1 script!
        cfg5_args += " --scriptLocations $ws_root_path/" + ctx.file.script.dirname

    cfg5_ps_script_file = ctx.actions.declare_file(ctx.label.name + ".ps1")
    powershell_command = _CFG5_START_POWERSHELL_TEMPLATE.format(
        script_short_path = cfg5_ps_script_file.short_path,
        script_package_path = cfg5_ps_script_file.path,
        cfg5_bin_path = info.cfg5_path.path,
        dpa_file_path = ctx.file.dpa.path,
        cfg5_args = cfg5_args,
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
            runfiles = ctx.runfiles(files = [cfg5_ps_script_file] + runfiles),
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
        "config_files": attr.label_list(
            allow_files = True,
            mandatory = False,
            doc = "Additional configuration files to start the cfg5 with",
        ),
        "cfg5_args": attr.string(
            mandatory = False,
            doc = "Additional CFG5 arguments",
        ),
        "script": attr.label(
            allow_single_file = [".jar"],
            mandatory = False,
            doc = "Script task which script location is added to the CFG5",
        ),
    },
    executable = True,
    toolchains = ["//rules/cfg5:toolchain_type"],
)
