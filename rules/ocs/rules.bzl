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

"""Rules for ocs"""

load("//rules/common:copy_file.bzl", "copy_file")

_OCS_TEMPLATE_ENV_VAR_LINUX = "export DOTNET_ROOT=$PWD/{dotnet_path} && "

_CREATE_PROJECT_TEMPLATE_WINDOWS = """
(Get-Content -Path "{create_project_file}" -Raw | ConvertFrom-Json | ForEach-Object {{ $_.generalSettings.projectFolder = "$PWD/{create_project_dir}"; 
$_.developerWorkspace.developerExecutable = "{developer_path}"; 
$_ }}) | ConvertTo-Json -Depth 32 | Set-Content -Path "{create_project_file}"; 
"""

_CREATE_PROJECT_TEMPLATE_LINUX = """
jsonContent=$(jq '.' "{create_project_file}") &&
jsonContent=$(echo "$jsonContent" | jq --arg pwd "$PWD" --arg dir "{create_project_dir}" '.generalSettings.projectFolder = "\\($pwd)/\\($dir)"') &&
jsonContent=$(echo "$jsonContent" | jq --arg pwd "$PWD" --arg dir "{developer_path}" '.developerWorkspace.developerExecutable = "\\($pwd)/\\($dir)"') &&
echo "$jsonContent" | jq '.' > "{create_project_file}" && 
"""

_INPUTFILE_TEMPLATE_WINDOWS = """
$newPath = "{file_path}"; 
$jsonContent = Get-Content -Path "{inputfile_file}" -Raw | ConvertFrom-Json; 
$jsonContent.inputFiles | ForEach-Object {{ if ( ($_.path -split "/")[-1] -eq ($newPath -split "/")[-1] ) {{ $_.path = "$PWD/$newPath"; $_ }} }}; 
$jsonContent | ConvertTo-Json -Depth 32 | Set-Content -Path "{inputfile_file}"; 
"""

_INPUTFILE_TEMPLATE_LINUX = """
newPath={file_path} &&
jsonContent=$(jq '.' {inputfile_file}) &&
jsonContent=$(echo "$jsonContent" | jq --arg newPath "$newPath" --arg pwd "$PWD" '.inputFiles |= map(if (.path | split("/")[-1] == ($newPath | split("/")[-1])) then .path = "\\($pwd)/\\($newPath)" else . end)') &&
echo $jsonContent | jq '.' > {inputfile_file} && 
"""

_CFG5_SCRIPT_TEMPLATE_WINDOWS = """
exit (start-process -WorkingDirectory  ./ -PassThru -NoNewWindow -RedirectStandardOutput {output_folder}/daVinciCfg5.log -Wait {cfg5cli_path} -ArgumentList '--scriptLocations {script_location} -s {script_task} {task_args} {cfg5_args} --ignoreUserScriptLocations --verbose').ExitCode
"""

_CFG5_SCRIPT_TEMPLATE_LINUX = """
{cfg5cli_path} --scriptLocations {script_location} -s {script_task} {task_args} {cfg5_args} --ignoreUserScriptLocations --verbose > {output_folder}/daVinciCfg5.log
"""

_REMOVE_WRITE_PROTECTION_TEMPLATE_WINDOWS = "Get-ChildItem -Path {} -Recurse | ForEach-Object {{ if ($_.PSIsContainer -eq $false -and $_.GetType().GetProperty('IsReadOnly')) {{ $_.IsReadOnly = $false }} }}; "

_REMOVE_WRITE_PROTECTION_TEMPLATE_LINUX = "find {} -type f -exec chmod -v u+w {{}} \\; && "

def _resolve_developer(ctx):
    info_davinci_developer = ctx.toolchains["//rules/davinci_developer:toolchain_type"]

    # linux and windows use different executables
    if ctx.attr.private_is_windows:
        if not info_davinci_developer.davinci_developer_label and not info_davinci_developer.davinci_developer_path:
            fail("Developer toolchain is needed for DaVinci Team and needs either one of davinci_developer_label or davinci_developer_path defined")
        developer_path = info_davinci_developer.davinci_developer_label.path if info_davinci_developer.davinci_developer_label else info_davinci_developer.davinci_developer_path + "/Bin/DaVinciDEV.exe"

    else:
        if not info_davinci_developer.davinci_developer_cmd_label:
            fail("Developer toolchain is needed for DaVinci Team and linux needs davinci_developer_cmd_label defined")
        developer_path = info_davinci_developer.davinci_developer_cmd_label.path

    return developer_path

def _resolve_cfg5cli(ctx):
    info_davinci_configurator = ctx.toolchains["//rules/cfg5:toolchain_type"]

    if not info_davinci_configurator.cfg5cli_path:
        fail("Cfg5 toolchain is needed for OCS and needs cfg5cli_path defined")
    cfg5cli = info_davinci_configurator.cfg5cli_path.path

    return cfg5cli

def _format_createproject(ctx, ocs_config):
    # modify the location of the created project in the json file
    create_project_file_path = "CreateProject.json"
    project_dir = ctx.outputs.result[0].dirname.split("/" + ctx.label.name)[0] + "/" + ctx.label.name

    developer_path = _resolve_developer(ctx)

    for file in ocs_config:
        if (file.basename == create_project_file_path):
            create_project_file_path = file.path

    create_project_template = _CREATE_PROJECT_TEMPLATE_WINDOWS if ctx.attr.private_is_windows else _CREATE_PROJECT_TEMPLATE_LINUX

    create_project_cmd = create_project_template.format(
        create_project_file = create_project_file_path,
        create_project_dir = project_dir,
        developer_path = developer_path,
    )

    return create_project_cmd

def _format_inputfiles_update(ctx, ocs_config):
    # modify the location of the inputfiles in the json file
    inputfile_cmd = ""
    inputfile_update_file_path = "InputFilesUpdate.json"

    for file in ocs_config:
        if (file.basename == inputfile_update_file_path):
            inputfile_update_file_path = file.path

    inputfile_template = _INPUTFILE_TEMPLATE_WINDOWS if ctx.attr.private_is_windows else _INPUTFILE_TEMPLATE_LINUX

    for file in ctx.files.input_files:
        inputfile_cmd += inputfile_template.format(
            inputfile_file = inputfile_update_file_path,
            file_path = file.path,
        )

    return inputfile_cmd

def _copy_config(ctx):
    workspace_name = ctx.label.name

    command = ""
    command_separator = " ;" if ctx.attr.private_is_windows else " &&"

    # copies the dpa file and removes the write protection
    dpa_copy = ctx.actions.declare_file(workspace_name + "/" + ctx.file.dpa_file.basename)
    command += "cp {} {}{} ".format(ctx.file.dpa_file.path, dpa_copy.path, command_separator)

    config_output = []

    # this copies all the config files
    for file in ctx.files.davinci_project_files:
        # this will put the config files inside the Config folder, this might need to be changed later on
        # but is needed to make sure that no deep paths are created in the workspace creation phase
        base_path = file.path.removeprefix(ctx.file.dpa_file.dirname)
        config_out = ctx.actions.declare_file(workspace_name + "/" + base_path)

        config_output.append(config_out)
        command += "cp {} {}{} ".format(file.path, config_out.path, command_separator)

    # Remove the write protection from the project
    if ctx.attr.private_is_windows:
        command += _REMOVE_WRITE_PROTECTION_TEMPLATE_WINDOWS.format(dpa_copy.dirname)
    else:
        command += _REMOVE_WRITE_PROTECTION_TEMPLATE_LINUX.format(dpa_copy.dirname)

    return [command, dpa_copy]

def _ocs_impl(ctx):
    inputs = ctx.files.davinci_project_files + ctx.files.ocs_config_files + [ctx.file.ocs_app] + ctx.files.input_files
    output_folder = "{}/{}".format(ctx.bin_dir.path, ctx.label.name)
    cfg5_args = ctx.attr.cfg5_args
    ocs_args = ""
    dotnet_path = ""
    additional_cmds = ""
    config_file_names = [f.basename for f in ctx.files.ocs_config_files]

    # OCS home is one dir out of the plugins json files
    if (ctx.files.ocs_config_files != []):
        # Copy the ocs config files so that they can be modified without destroying cache hits
        workspace_name = ctx.label.name + "_ws"
        ocs_workspace = []
        for file in ctx.files.ocs_config_files:
            base_path = file.path.removeprefix("{}/{}".format(ctx.bin_dir.path, ctx.label.name))
            ocs_config_file = ctx.actions.declare_file(workspace_name + "/" + base_path)

            ocs_workspace.append(ocs_config_file)
            copy_file(ctx, file, ocs_config_file, ctx.attr.private_is_windows)

        inputs += ocs_workspace

        if ctx.attr.private_is_windows:
            additional_cmds += _REMOVE_WRITE_PROTECTION_TEMPLATE_WINDOWS.format(ocs_workspace[0].dirname)
        else:
            additional_cmds += _REMOVE_WRITE_PROTECTION_TEMPLATE_LINUX.format(ocs_workspace[0].dirname)

        if ("CreateProject.json" in config_file_names):
            additional_cmds += _format_createproject(ctx, ocs_workspace)

            # Dotnet path for developer in linux, only needed for project creation
            if (ctx.attr.private_is_windows == False):
                dotnet_path = ctx.toolchains["@rules_dotnet//dotnet:toolchain_type"].dotnetinfo.runtime_path.split("/dotnet")[0]

        if ("InputFilesUpdate.json" in config_file_names):
            additional_cmds += _format_inputfiles_update(ctx, ocs_workspace)

        ocs_args += '"--home {}"'.format(ocs_workspace[0].dirname.split("/plugins")[0])

    if (ctx.file.dpa_file):
        inputs.append(ctx.file.dpa_file)
        cp_command, dpa_copy = _copy_config(ctx)
        additional_cmds += cp_command

        if ("CreateProject.json" not in config_file_names):
            # When a dpa file is specified we load the config directly, so that the CreateProject.json does not have to be specified.
            cfg5_args += " -p {}".format(dpa_copy.path)

    cf5gcli = _resolve_cfg5cli(ctx)

    if (ocs_args):
        ocs_args = "--taskArgs {}".format(ocs_args)

    if (ctx.attr.private_is_windows):
        cmd_template = _CFG5_SCRIPT_TEMPLATE_WINDOWS
    else:
        cmd_template = _CFG5_SCRIPT_TEMPLATE_LINUX

    command = cmd_template.format(
        cfg5cli_path = cf5gcli,
        output_folder = output_folder,
        script_location = ctx.file.ocs_app.dirname,
        script_task = ctx.attr.ocs_app_name or "OCS",
        task_args = ocs_args,
        cfg5_args = cfg5_args.replace("$(OUTS)", output_folder),
    )
    concatenated_cmd = additional_cmds + command

    if (ctx.attr.private_is_windows):
        ctx.actions.run(
            mnemonic = "ocsWindows",
            executable = "powershell.exe",
            progress_message = "Executing OCS script %s" % ctx.file.ocs_app.dirname,
            arguments = [concatenated_cmd],
            env = {
                "CommonProgramFiles": "C:\\Program Files (x86)\\Common Files",  # Path to common shared lib from cfg5 external dependencies
                "OS": "Windows_NT",
                "windir": "C:\\Windows",
                "SystemRoot": "C:\\Windows",
            },
            inputs = inputs,
            outputs = ctx.outputs.result,
        )

    else:
        env_vars = _OCS_TEMPLATE_ENV_VAR_LINUX.format(dotnet_path = dotnet_path)
        ctx.actions.run_shell(
            mnemonic = "ocsLinux",
            progress_message = "Executing OCS script %s" % ctx.file.ocs_app.dirname,
            command = env_vars + concatenated_cmd,
            inputs = inputs,
            outputs = ctx.outputs.result,
        )

    return [
        DefaultInfo(files = depset(ctx.outputs.result)),
    ]

ocs_attrs = {
    "cfg5_args": attr.string(doc = "Additional arguments for the cfg5 run"),
    "ocs_app": attr.label(allow_single_file = True, doc = "The .jar file of the ocs app"),
    "dpa_file": attr.label(mandatory = False, allow_single_file = True, doc = "The .dpa file if a project is modified and not created"),
    "ocs_app_name" : attr.string(mandatory = False, doc = "The name of the ocs app, used to execute the proper script in .jar file"),
    "input_files": attr.label_list(allow_empty = True, allow_files = [".arxml", ".cdd", ".dbc"], doc = "Inputfiles if inputfile update is executed"),
    "davinci_project_files": attr.label_list(allow_empty = True, allow_files = True, doc = "Project files if a project is modified"),
    "ocs_config_files": attr.label_list(allow_empty = True, allow_files = [".json"], doc = "The ocs plugin json files from ocs home directory"),
    "private_is_windows": attr.bool(mandatory = True, doc = "Set automatically for the correct OS"),
    "result": attr.output_list(mandatory = True, doc = "OCS run output files"),
}

ocs_def = rule(
    implementation = _ocs_impl,
    attrs = ocs_attrs,
    doc = """Run the cfg5 and execute the OCS as script task. Can be used to create a project or to run on an existing one.
$(OUTS) variable can be used in cfg5_args to be replaced with the output directory of the rule.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
""",
    toolchains = [
        "//rules/davinci_developer:toolchain_type",
        "//rules/cfg5:toolchain_type",
        config_common.toolchain_type("@rules_dotnet//dotnet:toolchain_type", mandatory = False),
    ],
)

def ocs(name, **kwargs):
    ocs_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

def _cfg5_execute_script_task_impl(ctx):
    inputs = ctx.files.davinci_project_files + [ctx.file.script]

    output_folder = "{}/{}".format(ctx.bin_dir.path, ctx.label.name)
    additional_command = ""

    cf5gcli = _resolve_cfg5cli(ctx)
    cfg5_args = ctx.attr.cfg5_args

    task_args = ctx.attr.task_args.replace("$(OUTS)", output_folder)
    if (task_args):
        task_args = "--taskArgs {}".format(task_args)

    if (ctx.attr.private_is_windows):
        cmd_template = _CFG5_SCRIPT_TEMPLATE_WINDOWS
    else:
        cmd_template = _CFG5_SCRIPT_TEMPLATE_LINUX

    # Load the project if a .dpa is specified
    if (ctx.file.dpa_file):
        inputs = [ctx.file.dpa_file]
        additional_command, dpa_copy = _copy_config(ctx)
        cfg5_args += " -p {}".format(dpa_copy.path)

    command = cmd_template.format(
        cfg5cli_path = cf5gcli,
        output_folder = output_folder,
        script_location = ctx.file.script.dirname,
        script_task = ctx.attr.script_task,
        task_args = task_args,
        cfg5_args = cfg5_args.replace("$(OUTS)", output_folder),
    )

    if ctx.attr.private_is_windows:
        ctx.actions.run(
            mnemonic = "cfg5ScriptWindows",
            executable = "powershell.exe",
            progress_message = "Executing script task %s" % ctx.attr.script_task,
            arguments = [additional_command + command],
            env = {
                "CommonProgramFiles": "C:\\Program Files (x86)\\Common Files",  # Path to common shared lib from cfg5 external dependencies
                "OS": "Windows_NT",
                "windir": "C:\\Windows",
                "SystemRoot": "C:\\Windows",
            },
            inputs = inputs,
            outputs = ctx.outputs.result,
        )

    else:
        ctx.actions.run_shell(
            mnemonic = "cfg5ScriptLinux",
            progress_message = "Executing script task %s" % ctx.attr.script_task,
            command = additional_command + command,
            inputs = inputs,
            outputs = ctx.outputs.result,
        )

    return [
        DefaultInfo(files = depset(ctx.outputs.result)),
    ]

cfg5_script_task_attrs = {
    "cfg5_args": attr.string(doc = "Additional arguments for the cfg5 run"),
    "script_task": attr.string(doc = "Name of the script task"),
    "task_args": attr.string(doc = "Script task arguments"),
    "script": attr.label(mandatory = True, allow_single_file = True, doc = "The .jar/.dvgroovy file"),
    "dpa_file": attr.label(mandatory = False, allow_single_file = True, doc = "The .dpa project file"),
    "davinci_project_files": attr.label_list(allow_empty = True, allow_files = True, doc = "Project files if a project is modified"),
    "private_is_windows": attr.bool(mandatory = True, doc = "Set automatically to the correct OS value"),
    "result": attr.output_list(mandatory = True, doc = "OCS run output files"),
}

cfg5_execute_script_task_def = rule(
    implementation = _cfg5_execute_script_task_impl,
    attrs = cfg5_script_task_attrs,
    doc = """Run the cfg5 and execute a script task.
$(OUTS) variable can be used in cfg5_args and task_args to be replaced with the output directory of the rule.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
""",
    toolchains = ["//rules/cfg5:toolchain_type"],
)

def cfg5_execute_script_task(name, **kwargs):
    cfg5_execute_script_task_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
