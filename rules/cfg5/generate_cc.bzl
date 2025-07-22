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

"""Rule to generate Config 5 from Baze and return CcInfo"""

load("//rules/common:create_davinci_tool_workspace.bzl", "create_davinci_tool_workspace")
# load("//rules/vtt:toolchains.bzl", "generate_tools_vtt")

_CFG5_GENERATE_TEMPLATE_WINDOWS_WORKSPACE = """
$folderPath = '{dpa_folder}'
Get-ChildItem -Path $folderPath -Recurse -File | ForEach-Object {{ $_.IsReadOnly = $false; $_.Attributes = 'Normal'}}
start-process -WorkingDirectory  {dpa_folder} -PassThru -NoNewWindow -RedirectStandardOutput {dpa_folder}/daVinciCfg5.log -Wait {cfg5cli_path} -ArgumentList '-p {dpa_path} -g {genargs} --verbose'
"""

_CFG5_GENERATE_TEMPLATE_LINUX_WORKSPACE = """
sudo chmod -R 777 {dpa_folder} &&
{cfg5cli_path} -p  {dpa_folder}/{dpa_path} -g {genargs} --verbose > {dpa_folder}/daVinciCfg5.log
"""

EXCLUDED_FILES_GENERIC = ["*.json*", "*.sha512*", "*.rc*", "*.mak*", "*.ORT*", "*.html*", "*.oil*", "*.checksum*", "*.arxml*", "*.versioncollection*", "*.xml*", "*.lsl*", "*.executionResult*"]
EXCLUDED_FILES_RT = [
    "Mcu_Cfg.h",
    "Mcu_PBcfg.c",
    "Port_Cfg.h",
    "Port_PBcfg.c",
    "*Rte_Vtt*",
    "*CANoeEmu*",
    "*Vtt*",
]
EXCLUDED_FILES_VTT = ["vLinkGen_Lcfg.c", "vBrs_Lcfg.c", "BrsTccCfg.h"]
GEN_ARG_VTT = "--genType=VTT"
GEN_ARG_RT = "--genType=REAL"

_FILTER_CMD_LINUX = """
set -e -o pipefail

# Filter generated files to include only needed files
mkdir -p "{headers_dir}"
mkdir -p "{sources_dir}"

{rsync_exe} --log-file="{rsync_log_file_srcs}" --verbose --prune-empty-dirs --archive --itemize-changes --quiet {excluded_files_patterns} --filter "- **/*.h" {generator_output_dir} {sources_dir}
{rsync_exe} --log-file="{rsync_log_file_hdrs}" --verbose --prune-empty-dirs --archive --itemize-changes --quiet {excluded_files_patterns} --filter "- **/*.c" {generator_output_dir} {headers_dir}
"""

_FILTER_CMD_WINDOWS = """
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

try {{

    # List of files to ignore
    $ignoreList = @({excluded_files})

    # Function to check if a file is in the ignore list
    function ShouldIgnore {{
        param (
            [string]$fileName
        )
        return $ignoreList -contains $fileName
    }}

    # Create destination folders if they don't exist
    if (-not (Test-Path -Path {sources_dir})) {{
        New-Item -ItemType Directory -Path {sources_dir}
    }}

    if (-not (Test-Path -Path {headers_dir})) {{
        New-Item -ItemType Directory -Path {headers_dir}
    }}

    # Move .c and .h files to respective folders
    Get-ChildItem -Path {generator_output_dir} -Filter *.c -Recurse | ForEach-Object {{
        if (-not (ShouldIgnore -fileName $_.Name)) {{
            Move-Item -Path $_.FullName -Destination {sources_dir}
        }}
    }}

    Get-ChildItem -Path {generator_output_dir} -Filter *.h -Recurse | ForEach-Object {{
        if (-not (ShouldIgnore -fileName $_.Name)) {{
            Move-Item -Path $_.FullName -Destination {headers_dir}
        }}
    }}

    Write-Output "Files have been moved successfully."
}} catch {{
    Write-Error "An error occurred: $_"
    exit 1
}}
"""

def _cfg5_generate_cc(ctx, dpa_path, dpa_folder, inputs, template, additional_genargs, tools = []):
    info = ctx.toolchains["//rules/cfg5:toolchain_type"]

    dvcfg5_report_file_name = "DVCfg5ReportFile.xml"
    dvcfg5_report_file = ctx.actions.declare_file(ctx.label.name + "/" + dvcfg5_report_file_name)

    # Using the gen args to parse the gen_type to use the correct filtering for vtt and rt
    # Currently this rule is limited by ONE generation output per vtt and rt as the root level output directory is used
    gen_type = GEN_ARG_RT if GEN_ARG_RT in additional_genargs else GEN_ARG_VTT
    gen_dir = "GenDataVtt" if gen_type == GEN_ARG_VTT else "GenData"

    excluded_files_patterns = EXCLUDED_FILES_GENERIC + EXCLUDED_FILES_VTT if gen_type == GEN_ARG_VTT else EXCLUDED_FILES_GENERIC + EXCLUDED_FILES_RT
    excluded_files_patterns_string = "--filter \"- **/" + "\" --filter \"- **/".join(excluded_files_patterns) + "\""

    if "/" in dpa_folder:
        dvcfg5_log_file_name = dpa_folder.split("/")[-1] + "/daVinciCfg5.log"
    else:
        dvcfg5_log_file_name = dpa_folder + "/daVinciCfg5.log"
    dvcfg5_log_file = ctx.actions.declare_file(dvcfg5_log_file_name)

    dvcfg5_output_dir = ctx.actions.declare_directory(gen_dir)

    sources_dir = ctx.actions.declare_directory(ctx.label.name + "/generated_sources")
    headers_dir = ctx.actions.declare_directory(ctx.label.name + "/generated_headers")
    generate_tools = list(tools)

    # TODO Remove for later versions - Check only for backwards compatibility, as the cfg5_files are only for hermitic execution
    if info.cfg5_files:
        generate_tools.extend(info.cfg5_files)
    else:
        generate_tools.append(info.cfg5cli_path)

    if ctx.attr.private_is_windows:
        # For Windows we have to hack the path to the dvcfg5_report_file, because we switch the working directory to the dpa_folder when executing DVCfg5.
        # This leads to the problem that the tool saves the report on the wrong place because the output path is relative.
        report_file_path = "../" + ctx.label.name + "/" + dvcfg5_report_file.basename
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
            outputs = [dvcfg5_output_dir] + [dvcfg5_report_file, dvcfg5_log_file],
            arguments = ["-NoProfile", command],
            env = {"OS": "Windows_NT", "windir": "C:\\Windows", "SystemRoot": "C:\\Windows"},
        )

        filter_cmd_windows = _FILTER_CMD_WINDOWS.format(
            generator_output_dir = dvcfg5_output_dir.path,
            sources_dir = sources_dir.path,
            headers_dir = headers_dir.path,
            excluded_files = '"' + '","'.join(EXCLUDED_FILES_VTT) + '"' if gen_type == GEN_ARG_VTT else "",
        )

        filter_files_powershell_script_file = ctx.actions.declare_file("filter_files.ps1")
        ctx.actions.write(
            output = filter_files_powershell_script_file,
            content = filter_cmd_windows,
            is_executable = True,
        )

        ctx.actions.run(
            mnemonic = "cfg5FileFiltering",
            executable = "powershell.exe",
            inputs = depset([dvcfg5_output_dir]),
            tools = depset([filter_files_powershell_script_file]),
            outputs = [sources_dir, headers_dir],
            arguments = ["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-File", filter_files_powershell_script_file.path],
        )
        compilation_context = cc_common.create_compilation_context(
            headers = depset(
                [headers_dir],
            ),
            includes = depset(
                [
                    headers_dir.path,
                ],
            ),
        )

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
            outputs = [dvcfg5_output_dir] + [dvcfg5_report_file, dvcfg5_log_file],
            command = command,
        )

        rsync_log_file_srcs = ctx.actions.declare_file("file_filter_srcs.log")
        rsync_log_file_hrds = ctx.actions.declare_file("file_filter_hrds.log")

        filter_cmd_linux = _FILTER_CMD_LINUX.format(
            generator_output_dir = dvcfg5_output_dir.path,
            sources_dir = sources_dir.path,
            headers_dir = headers_dir.path,
            rsync_exe = ctx.executable.rsync.path,
            excluded_files_patterns = excluded_files_patterns_string,
            rsync_log_file_srcs = rsync_log_file_srcs.path,
            rsync_log_file_hdrs = rsync_log_file_hrds.path,
        )

        ctx.actions.run_shell(
            inputs = depset([dvcfg5_output_dir] + [ctx.executable.rsync]),
            outputs = [sources_dir, headers_dir] + [rsync_log_file_srcs, rsync_log_file_hrds],
            progress_message = "Filtering files",
            command = filter_cmd_linux,
        )

        compilation_context = cc_common.create_compilation_context(
            headers = depset(
                [headers_dir],
            ),
            includes = depset(
                [
                    headers_dir.path + "/" + gen_dir,
                    headers_dir.path + "/" + gen_dir + "/Components",
                ],
            ),
        )

    return [
        DefaultInfo(files = depset([sources_dir] + [headers_dir] + [dvcfg5_report_file, dvcfg5_log_file])),
        CcInfo(compilation_context = compilation_context),
    ]

def _cfg5_generate_workspace_cc_impl(ctx, additional_genargs, tools = []):
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
    return _cfg5_generate_cc(ctx, dpa_path, dpa_folder, inputs, template, additional_genargs, tools)

# def _cfg5_generate_vtt_workspace_cc_impl(ctx):
#     tools = generate_tools_vtt(ctx)
#     return _cfg5_generate_workspace_cc_impl(ctx, ["--genType=VTT", "--buildVTTProject"], tools)

cfg5_generate_workspace_cc_attrs = {
    "dpa_file": attr.label(allow_single_file = [".dpa"], doc = "Dpa project file to start the cfg5 with"),
    "config_files": attr.label_list(allow_files = True, doc = "Additional configuration files to start the cfg5 with"),
    "genArgs": attr.string_list(doc = "The DaVinciCfgCmd argument options."),
    "sip": attr.label(doc = "sip location to mark it as a dependency, as it the sip is needed for cfg5 execution"),
    "private_is_windows": attr.bool(mandatory = True, doc = "Is set automatically to the correct OS value"),
    # "A List of the folders where the config files reside, this cannot be detected automatically, as only the current package can be resolved elegantly"
    "config_folders": attr.string_list(doc = "(Optional) List of config folders that the path will be checked for in each file to create a nested Config folder structure, default is [\"Config\"]", default = ["Config"]),
    "rsync": attr.label(executable = True, cfg = "exec", default = Label("@ape//ape:rsync")),
}

# cfg5_generate_vtt_workspace_cc_def = rule(
#     implementation = _cfg5_generate_vtt_workspace_cc_impl,
#     attrs = cfg5_generate_workspace_cc_attrs,
#     doc = """
# Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
# This rule is wrapped with private_is_windows attribute to separate between OS differences.
# Used specifically for the vtt use case, as this adds the correct vtt flags to the Cfg5 call automatically.
# """,
#     toolchains = ["//rules/cfg5:toolchain_type", "//rules/vtt:toolchain_type"],
# )

# def cfg5_generate_vtt_workspace_cc(name, **kwargs):
#     """Wraps the cfg5_generate_vtt_workspace_cc with the private_is_windows select statement in place

#     Args:
#         name: The unique name of this target
#         **kwargs: All of the attrs of the cfg5_generate_vtt_workspace_cc rule

#     Returns:
#         A cfg5_generate_vtt_workspace_cc_def rule that contains the actual implementation
#     """
#     cfg5_generate_vtt_workspace_cc_def(
#         name = name,
#         private_is_windows = select({
#             "@bazel_tools//src/conditions:host_windows": True,
#             "//conditions:default": False,
#         }),
#         **kwargs
#     )

def _cfg5_generate_rt_workspace_cc_impl(ctx):
    return _cfg5_generate_workspace_cc_impl(ctx, ["--genType=REAL"])

cfg5_generate_rt_workspace_cc_def = rule(
    implementation = _cfg5_generate_rt_workspace_cc_impl,
    attrs = cfg5_generate_workspace_cc_attrs,
    doc = """
Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
Used specifically for the rt use case, as this adds the correct rt flags to the Cfg5 call automatically.
""",
    toolchains = ["//rules/cfg5:toolchain_type"],
)

def cfg5_generate_rt_workspace_cc(name, **kwargs):
    """Wraps the cfg5_generate_rt_workspace_cc with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        **kwargs: All of the attrs of the cfg5_generate_rt_workspace_cc rule

    Returns:
        A cfg5_generate_rt_workspace_cc_def rule that contains the actual implementation
    """
    cfg5_generate_rt_workspace_cc_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
