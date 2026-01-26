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

"""Rule to generate DaVinciConfigurator 5 config from Bazel and return CcInfo"""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@rules_common//:create_davinci_tool_workspace.bzl", "create_davinci_tool_workspace")

# Custom provider to hold multiple CcInfo objects
MultipleCcInfo = provider(
    doc = "Provider that contains multiple CcInfo objects for different components",
    fields = {
        "main": "Main CcInfo containing all generated files",
        "components": "Dictionary of component name to CcInfo mapping",
        "component_names": "List of component names",
    },
)

_CFG5_GENERATE_TEMPLATE_WINDOWS_WORKSPACE = """
$folderPath = '{dpa_folder}'
Get-ChildItem -Path $folderPath -Recurse -File | ForEach-Object {{ $_.IsReadOnly = $false; $_.Attributes = 'Normal'}}
exit (start-process -WorkingDirectory  {dpa_folder} -PassThru -NoNewWindow -RedirectStandardOutput {dpa_folder}/daVinciCfg5.log -Wait {cfg5cli_path} -ArgumentList '-p {dpa_path} -g {genargs} --verbose').ExitCode
"""

_CFG5_GENERATE_TEMPLATE_LINUX_WORKSPACE = """
sudo chmod -R 777 {dpa_folder} &&
{cfg5cli_path} -p  {dpa_folder}/{dpa_path} -g {genargs} --verbose > {dpa_folder}/daVinciCfg5.log
"""

EXCLUDED_FILES_VTT = ["vLinkGen_Lcfg.c", "vBrs_Lcfg.c", "BrsTccCfg.h"]
GEN_ARG_VTT = "--genType=VTT"
GEN_ARG_RT = "--genType=REAL"

def _cfg5_generate(ctx, dpa_path, dpa_folder, inputs, template, additional_genargs, tools = []):
    info = ctx.toolchains["@rules_cfg5//:toolchain_type"]

    dvcfg5_report_file_name = "DVCfg5ReportFile.xml"
    dvcfg5_report_file = ctx.actions.declare_file(ctx.label.name + "/" + dvcfg5_report_file_name)

    # Using the gen args to parse the gen_type to use the correct filtering for vtt and rt
    # Currently this rule is limited by ONE generation output per vtt and rt as the root level output directory is used
    gen_type = GEN_ARG_RT if GEN_ARG_RT in additional_genargs else GEN_ARG_VTT
    gen_dir = "GenDataVtt" if gen_type == GEN_ARG_VTT else "GenData"

    excluded_files_patterns = ctx.attr.excluded_files + (EXCLUDED_FILES_VTT if gen_type == GEN_ARG_VTT else [])
    excluded_files_patterns_string = "--filter \"- **/" + "\" --filter \"- **/".join(excluded_files_patterns) + "\""

    additional_source_file_endings = ctx.attr.additional_source_file_endings
    additional_source_file_endings_string = "--filter \"+ **/" + "\" --filter \"+ **/".join(additional_source_file_endings) + "\""

    if "/" in dpa_folder:
        dvcfg5_log_file_name = dpa_folder.split("/")[-1] + "/daVinciCfg5.log"
    else:
        dvcfg5_log_file_name = dpa_folder + "/daVinciCfg5.log"
    dvcfg5_log_file = ctx.actions.declare_file(dvcfg5_log_file_name)

    dvcfg5_output_dir = ctx.actions.declare_directory(gen_dir)

    sources_dir = ctx.actions.declare_directory(ctx.label.name + "/generated_sources")
    headers_dir = ctx.actions.declare_directory(ctx.label.name + "/generated_headers")

    # Declare additional output files from the generator output directory
    additional_output_file_artifacts = []
    for additional_file in ctx.attr.additional_output_files:
        additional_output_file_artifacts.append(ctx.actions.declare_file(ctx.label.name + "/" + additional_file))

    # Add support for component-specific directories
    component_sources_dirs = []
    component_headers_dirs = []

    # Filter and sort components, excluding "main" for component-specific directories
    components = ctx.attr.components if hasattr(ctx.attr, "components") and ctx.attr.components else []
    actual_components = sorted([comp for comp in components if comp != "main"])

    # Only create component-specific directories if we have actual components
    for component in actual_components:
        comp_src_dir = ctx.actions.declare_directory(ctx.label.name + "/generated_sources_" + component)
        comp_hdr_dir = ctx.actions.declare_directory(ctx.label.name + "/generated_headers_" + component)
        component_sources_dirs.append(comp_src_dir)
        component_headers_dirs.append(comp_hdr_dir)
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

        # Build component directories list for PowerShell
        component_dirs_list = ""
        for i, component in enumerate(actual_components):
            if i < len(component_sources_dirs) and i < len(component_headers_dirs):
                comp_src_dir = component_sources_dirs[i]
                comp_hdr_dir = component_headers_dirs[i]
                component_dirs_list += ', "{}", "{}"'.format(comp_src_dir.path, comp_hdr_dir.path)

        filter_files_powershell_script_file = ctx.actions.declare_file("filter_files.ps1")

        ctx.actions.expand_template(
            template = ctx.file.private_filter_template,
            output = filter_files_powershell_script_file,
            substitutions = {
                "{generator_output_dir}": dvcfg5_output_dir.path,
                "{sources_dir}": sources_dir.path,
                "{headers_dir}": headers_dir.path,
                "{excluded_files}": '"' + '","'.join(ctx.attr.excluded_files) + ('","' + '","'.join(EXCLUDED_FILES_VTT) + '"' if gen_type == GEN_ARG_VTT else '"'),
                "{additional_source_file_endings}": '"' + '","'.join(ctx.attr.additional_source_file_endings) + '"',
                "{components_list}": '"' + '","'.join(actual_components) + '"',
                "{component_dirs_list}": component_dirs_list,
            },
            is_executable = True,
        )

        ctx.actions.run(
            mnemonic = "cfg5FileFiltering",
            executable = "powershell.exe",
            inputs = depset([dvcfg5_output_dir]),
            tools = depset([filter_files_powershell_script_file]),
            outputs = [sources_dir, headers_dir] + component_sources_dirs + component_headers_dirs,
            arguments = ["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-File", filter_files_powershell_script_file.path],
        )

        # Copy additional output files from generator output to their declared locations
        for i, additional_file in enumerate(ctx.attr.additional_output_files):
            src_path = dvcfg5_output_dir.path + "/" + additional_file
            dst_artifact = additional_output_file_artifacts[i]
            copy_cmd = "Copy-Item -Path '{}' -Destination '{}' -Force".format(src_path, dst_artifact.path)
            ctx.actions.run(
                mnemonic = "CopyAdditionalFile",
                executable = "powershell.exe",
                inputs = depset([dvcfg5_output_dir]),
                outputs = [dst_artifact],
                arguments = ["-NoProfile", "-Command", copy_cmd],
            )

        compilation_context = cc_common.create_compilation_context(
            headers = depset(
                [headers_dir],
            ),
            includes = depset(
                [headers_dir.path],
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

        # Build component directories creation commands for Linux
        component_dirs_creation = ""
        for i, component in enumerate(actual_components):
            if i < len(component_sources_dirs) and i < len(component_headers_dirs):
                comp_src_dir = component_sources_dirs[i]
                comp_hdr_dir = component_headers_dirs[i]
                component_dirs_creation += 'mkdir -p "{}"\n'.format(comp_src_dir.path)
                component_dirs_creation += 'mkdir -p "{}"\n'.format(comp_hdr_dir.path)

        # Build ignore files check for Linux
        ignore_files = ctx.attr.excluded_files + (EXCLUDED_FILES_VTT if gen_type == GEN_ARG_VTT else [])
        ignore_files_check = ""
        for ignore_file in ignore_files:
            ignore_files_check += 'if [ "$filename" = "{}" ]; then should_ignore=true; fi\n    '.format(ignore_file)

        # Read the Linux filter template from external file
        filter_files_bash_script_file = ctx.actions.declare_file("filter_files.sh")

        ctx.actions.expand_template(
            template = ctx.file.private_filter_template,
            output = filter_files_bash_script_file,
            substitutions = {
                "{generator_output_dir}": dvcfg5_output_dir.path,
                "{sources_dir}": sources_dir.path,
                "{headers_dir}": headers_dir.path,
                "{rsync_exe}": ctx.executable.rsync.path,
                "{excluded_files_patterns}": excluded_files_patterns_string,
                "{additional_source_file_endings}": additional_source_file_endings_string,
                "{rsync_log_file_srcs}": rsync_log_file_srcs.path,
                "{rsync_log_file_hdrs}": rsync_log_file_hrds.path,
                "{components_list}": " ".join(['"{}"'.format(comp) for comp in actual_components]),
                "{component_dirs_creation}": component_dirs_creation,
                "{ignore_files_check}": ignore_files_check,
            },
            is_executable = True,
        )

        ctx.actions.run(
            executable = "/bin/bash",
            inputs = depset([dvcfg5_output_dir] + [ctx.executable.rsync] + [filter_files_bash_script_file]),
            outputs = [sources_dir, headers_dir] + component_sources_dirs + component_headers_dirs + [rsync_log_file_srcs, rsync_log_file_hrds],
            progress_message = "Filtering files",
            arguments = [filter_files_bash_script_file.path],
        )

        # Copy additional output files from generator output to their declared locations
        for i, additional_file in enumerate(ctx.attr.additional_output_files):
            src_path = dvcfg5_output_dir.path + "/" + additional_file
            dst_artifact = additional_output_file_artifacts[i]
            copy_cmd = "cp '{}' '{}'".format(src_path, dst_artifact.path)
            ctx.actions.run_shell(
                mnemonic = "CopyAdditionalFile",
                inputs = [dvcfg5_output_dir],
                outputs = [dst_artifact],
                command = copy_cmd,
            )

        compilation_context = cc_common.create_compilation_context(
            headers = depset(
                [headers_dir] + component_headers_dirs,
            ),
            includes = depset(
                [
                    headers_dir.path + "/" + gen_dir,
                    headers_dir.path + "/" + gen_dir + "/Components",
                ] + [comp_hdr_dir.path for comp_hdr_dir in component_headers_dirs],
            ),
        )

    # Create separate CcInfo providers for different components
    # Main CcInfo containing all generated files (for backward compatibility)
    main_cc_info = CcInfo(compilation_context = compilation_context)

    # Create unmapped CcInfo with only headers_dir (no component-specific dirs)
    if ctx.attr.private_is_windows:
        unmapped_includes = [headers_dir.path]
    else:
        unmapped_includes = [
            headers_dir.path + "/" + gen_dir,
            headers_dir.path + "/" + gen_dir + "/Components",
        ]
    
    unmapped_compilation_context = cc_common.create_compilation_context(
        headers = depset([headers_dir]),
        includes = depset(unmapped_includes),
    )
    unmapped_cc_info = CcInfo(compilation_context = unmapped_compilation_context)

    # Create component-specific CcInfo providers only for actual components
    component_cc_infos = {}
    for i, component in enumerate(actual_components):
        if i < len(component_headers_dirs):
            # Include both component-specific and main headers for proper include resolution
            component_headers = [component_headers_dirs[i], headers_dir]

            if ctx.attr.private_is_windows:
                component_includes = [
                    component_headers_dirs[i].path,
                ]
            else:
                component_includes = [
                    component_headers_dirs[i].path,
                ]

            component_compilation_context = cc_common.create_compilation_context(
                headers = depset(component_headers),
                includes = depset(component_includes),
            )
            component_cc_info = CcInfo(compilation_context = component_compilation_context)
            component_cc_infos[component] = component_cc_info

    # Collect all output directories for DefaultInfo
    all_output_dirs = [sources_dir, headers_dir] + component_sources_dirs + component_headers_dirs

    # Add unmapped to components dict
    component_cc_infos["unmapped"] = unmapped_cc_info

    return [
        DefaultInfo(files = depset(additional_output_file_artifacts + all_output_dirs + [dvcfg5_report_file, dvcfg5_log_file])),
        main_cc_info,
        MultipleCcInfo(
            main = main_cc_info,
            components = component_cc_infos,
            component_names = actual_components + ["unmapped"],
        ),
    ]

def cfg5_generate_workspace_cc_impl(ctx, additional_genargs, tools = []):
    """Wraps the generate rule with the correct instantiation of variables

    Args:
        ctx: The current ctx with all of its attrs
        additional_genargs: All of the attrs of the cfg5_generate_workspace rule
        tools: All tools that shall be provided as input to the generate action

    Returns:
        _cfg5_generate call
    """
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
    return _cfg5_generate(ctx, dpa_path, dpa_folder, inputs, template, additional_genargs, tools)

cfg5_generate_workspace_cc_attrs = {
    "dpa_file": attr.label(allow_single_file = [".dpa"], doc = "Dpa project file to start the cfg5 with"),
    "config_files": attr.label_list(allow_files = True, doc = "Additional configuration files to start the cfg5 with"),
    "genArgs": attr.string_list(doc = "The DaVinciCfgCmd argument options"),
    "sip": attr.label(doc = "sip location to mark it as a dependency, as it the sip is needed for cfg5 execution"),
    "excluded_files": attr.string_list(doc = "(Optional) List of files to exclude from the generated files"),
    "additional_source_file_endings": attr.string_list(doc = "(Optional) List of additional file endings to copy to generated_sources on top of .c and assembler files"),
    "additional_output_files": attr.string_list(doc = "(Optional) List of paths to generated files (relative to generator output directory) that should be added to the output"),
    "components": attr.string_list(doc = "(Optional) List of component names to create separate CcInfo providers for", default = []),
    "private_is_windows": attr.bool(mandatory = True, doc = "Is set automatically to the correct OS value"),
    # "A List of the folders where the config files reside, this cannot be detected automatically, as only the current package can be resolved elegantly"
    "config_folders": attr.string_list(doc = "(Optional) List of config folders that the path will be checked for in each file to create a nested Config folder structure, default is [\"Config\"]", default = ["Config"]),
    "rsync": attr.label(executable = True, cfg = "exec", default = Label("@ape//ape:rsync")),
    "private_filter_template": attr.label(allow_single_file = True, mandatory = True, doc = "Is set automatically to the correct OS value"),
}

def _cfg5_generate_rt_workspace_cc_impl(ctx):
    return cfg5_generate_workspace_cc_impl(ctx, ["--genType=REAL"])

cfg5_generate_rt_workspace_cc_def = rule(
    implementation = _cfg5_generate_rt_workspace_cc_impl,
    attrs = cfg5_generate_workspace_cc_attrs,
    doc = """
Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
Used specifically for the rt use case, as this adds the correct rt flags to the Cfg5 call automatically.
""",
    toolchains = ["@rules_cfg5//:toolchain_type"],
)

# Helper rule to extract component CcInfo and source files
def _extract_component_cc_info_impl(ctx):
    multiple_cc_info = ctx.attr.src[MultipleCcInfo]
    component_name = ctx.attr.component

    if component_name in multiple_cc_info.components:
        if component_name == "unmapped":
            # For unmapped files, use the unmapped-specific CcInfo with only headers_dir
            component_cc_info = multiple_cc_info.components["unmapped"]
            directory_suffix = ""  # Unmapped files are in main directories without suffix
        else:
            component_cc_info = multiple_cc_info.components[component_name]
            directory_suffix = "_" + component_name

        # Get the source files from the main target's DefaultInfo
        main_default_info = ctx.attr.src[DefaultInfo]

        # Filter files to get component-specific source files
        component_source_files = []
        component_header_files = []

        for file in main_default_info.files.to_list():
            if file.path.endswith("/generated_sources" + directory_suffix):
                component_source_files.append(file)
            elif file.path.endswith("/generated_headers" + directory_suffix):
                component_header_files.append(file)

        # Create a filegroup-like behavior by returning both source and header files
        all_component_files = component_source_files + component_header_files

        return [
            DefaultInfo(files = depset(all_component_files)),
            component_cc_info,
        ]
    else:
        fail("Component '{}' not found. Available components: {}".format(
            component_name,
            multiple_cc_info.component_names,
        ))

extract_component_cc_info = rule(
    implementation = _extract_component_cc_info_impl,
    attrs = {
        "src": attr.label(mandatory = True, providers = [MultipleCcInfo]),
        "component": attr.string(mandatory = True),
    },
    provides = [CcInfo],
)
