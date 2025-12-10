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

_CREATE_PROJECT_TEMPLATE_WINDOWS = '(Get-Content -Path "{create_project_file}" -Raw | ConvertFrom-Json | ForEach-Object {{ $_.generalSettings.projectFolder = "$PWD/{create_project_dir}"; $_.developerWorkspace.developerExecutable = "{developer_path}"; $_ }}) | ConvertTo-Json -Depth 32 | Set-Content -Path "{create_project_file}"; '

_CREATE_PROJECT_TEMPLATE_LINUX = """
jsonContent=$(jq '.' "{create_project_file}") &&
jsonContent=$(echo "$jsonContent" | jq --arg pwd "$PWD" --arg dir "{create_project_dir}" '.generalSettings.projectFolder = "\\($pwd)/\\($dir)"') &&
jsonContent=$(echo "$jsonContent" | jq --arg pwd "$PWD" --arg dir "{developer_path}" '.developerWorkspace.developerExecutable = "\\($pwd)/\\($dir)"') &&
echo "$jsonContent" | jq '.' > "{create_project_file}" && 
"""

_INPUTFILE_TEMPLATE_WINDOWS = '$newPath = "{file_path}"; $jsonContent = Get-Content -Path "{inputfile_file}" -Raw | ConvertFrom-Json ; $jsonContent.inputFiles | ForEach-Object {{ if ( ($_.path -split "/")[-1] -eq ($newPath -split "/")[-1] ) {{ $_.path = "$PWD/$newPath"; $_ }} }} ; $jsonContent | ConvertTo-Json -Depth 32 | Set-Content -Path "{inputfile_file}"; '

_INPUTFILE_TEMPLATE_LINUX = """
newPath={file_path} &&
jsonContent=$(jq '.' {inputfile_file}) &&
jsonContent=$(echo "$jsonContent" | jq --arg newPath "$newPath" --arg pwd "$PWD" '.inputFiles |= map(if (.path | split("/")[-1] == ($newPath | split("/")[-1])) then .path = "\\($pwd)/\\($newPath)" else . end)') &&
echo $jsonContent | jq '.' > {inputfile_file} && 
"""

def _resolve_developer(ctx):
    info_davinci_developer = ctx.toolchains["@rules_davinci_developer//:toolchain_type"]

    # linux and windows use different executables
    if ctx.attr.private_is_windows:
        if not info_davinci_developer.davinci_developer_label and not info_davinci_developer.davinci_developer_path:
            fail("Developer toolchain is needed for DaVinci Team and needs either one of davinci_developer_label or davinci_developer_path defined")
        developer_path = info_davinci_developer.davinci_developer_label.path if info_davinci_developer.davinci_developer_label else info_davinci_developer.davinci_developer_path

    else:
        if not info_davinci_developer.davinci_developer_cmd_label:
            fail("Developer toolchain is needed for DaVinci Team and linux needs davinci_developer_cmd_label defined")
        developer_path = info_davinci_developer.davinci_developer_cmd_label.path

    return developer_path

def _resolve_cfg5cli(ctx):
    info_davinci_configurator = ctx.toolchains["@rules_cfg5//:toolchain_type"]

    if not info_davinci_configurator.cfg5cli_path:
        fail("Cfg5 toolchain is needed for OCS and needs cfg5cli_path defined")
    cfg5cli = info_davinci_configurator.cfg5cli_path.path

    return cfg5cli

def _format_createproject(ctx):
    # modify the location of the created project in the json file
    create_project_file_path = "CreateProject.json"
    project_dir = "{}/{}".format(ctx.bin_dir.path, ctx.label.name)

    developer_path = _resolve_developer(ctx)

    for file in ctx.files.ocs_config_files:
        if (file.basename == create_project_file_path):
            create_project_file_path = file.path

    create_project_template = _CREATE_PROJECT_TEMPLATE_WINDOWS if ctx.attr.private_is_windows else _CREATE_PROJECT_TEMPLATE_LINUX

    create_project_cmd = create_project_template.format(
        create_project_file = create_project_file_path,
        create_project_dir = project_dir,
        developer_path = developer_path,
    )

    return create_project_cmd

def _format_inputfiles_update(ctx):
    # modify the location of the inputfiles in the json file
    inputfile_cmd = ""
    inputfile_update_file_path = "InputFilesUpdate.json"

    for file in ctx.files.ocs_config_files:
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
    command = ""
    workspace_name = ctx.label.name

    command_seperator = " ;" if ctx.attr.private_is_windows else " &&"

    # copies the dpa file and removes the write protection
    dpa_copy = ctx.actions.declare_file(workspace_name + "/" + ctx.file.dpa_file.basename)
    command += "cp {} {}{} ".format(ctx.file.dpa_file.path, dpa_copy.path, command_seperator)

    config_output = []

    # this copies all the config files
    for file in ctx.files.davinci_project_files:
        # this will put the config files inside the Config folder, this might need to be changed later on
        # but is needed to make sure that no deep paths are created in the workspace creation phase
        base_path = file.path.removeprefix(ctx.file.dpa_file.dirname)
        config_out = ctx.actions.declare_file(workspace_name + "/" + base_path)

        config_output.append(config_out)
        command += "cp {} {}{} ".format(file.path, config_out.path, command_seperator)

    # Remove the writeprotection from the project
    if ctx.attr.private_is_windows:
        command += "Get-ChildItem -Path {} -Recurse | ForEach-Object {{ if ($_.PSIsContainer -eq $false -and $_.GetType().GetProperty('IsReadOnly')) {{ $_.IsReadOnly = $false }} }}; ".format(dpa_copy.dirname)

    else:
        command += "find {} -type f -exec chmod -v u+w {{}} \\; && ".format(dpa_copy.dirname)

    return [command, dpa_copy]

def _ocs_impl(ctx):
    inputs = ctx.files.davinci_project_files + ctx.files.ocs_config_files + [ctx.file.ocs_app] + ctx.files.input_files
    additional_cmds = ""
    cfg_args = ""
    config_file_names = [f.basename for f in ctx.files.ocs_config_files]

    # OCS home is one dir out of the plugins json files
    if (ctx.files.ocs_config_files != []):
        cfg_args += " --taskArgs \"OCS\" \"--home {}\"".format(ctx.files.ocs_config_files[0].dirname.split("/plugins")[0])

        if ("CreateProject.json" in config_file_names):
            additional_cmds += _format_createproject(ctx)
        if ("InputFilesUpdate.json" in config_file_names):
            additional_cmds += _format_inputfiles_update(ctx)

    if (ctx.file.dpa_file != None):
        inputs.append(ctx.file.dpa_file)
        ret = _copy_config(ctx)
        additional_cmds += ret[0]

        if ("CreateProject.json" not in config_file_names):
            # When a dpa file is specified and no ocs jsons, we load the config directly, so that the CreateProject.json does not have to be specified.
            cfg_args += " --project {}".format(ret[1].path)

    cf5gcli = _resolve_cfg5cli(ctx)

    if ctx.attr.private_is_windows:
        _command = "exit (start-process -WorkingDirectory ./ -NoNewWindow -Wait -PassThru {cfg5cli} -ArgumentList '--scriptLocations {script_location} --ignoreUserScriptLocations --scriptTask \"OCS\" {cfg_args} {ocs_args}').ExitCode "
        _command = _command.format(
            cfg5cli = cf5gcli,
            script_location = ctx.file.ocs_app.dirname,
            cfg_args = cfg_args,
            ocs_args = ctx.attr.ocs_args,
        )
        concatenated_ocs_cmd = additional_cmds + _command

        ctx.actions.run(
            mnemonic = "ocsWindows",
            executable = "powershell.exe",
            progress_message = "Executing OCS script %s" % ctx.file.ocs_app.dirname,
            arguments = [concatenated_ocs_cmd],
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
        _command = "{cfg5cli} --scriptLocations {script_location} --ignoreUserScriptLocations --scriptTask \"OCS\" {cfg_args} {ocs_args} "
        _command = _command.format(
            cfg5cli = cf5gcli,
            script_location = ctx.file.ocs_app.dirname,
            cfg_args = cfg_args,
            ocs_args = ctx.attr.ocs_args,
        )
        concatenated_ocs_cmd = additional_cmds + _command

        ctx.actions.run_shell(
            mnemonic = "ocsLinux",
            progress_message = "Executing OCS script %s" % ctx.file.ocs_app.dirname,
            command = concatenated_ocs_cmd,
            inputs = inputs,
            outputs = ctx.outputs.result,
        )

    return [
        DefaultInfo(files = depset(ctx.outputs.result)),
    ]

ocs_attrs = {
    "ocs_args": attr.string(doc = "The args for the actual ocs run"),
    "ocs_app": attr.label(allow_single_file = True, doc = "The .jar file of the ocs app"),
    "dpa_file": attr.label(mandatory = False, allow_single_file = True, doc = "The .dpa file if a project is modified and not created"),
    "input_files": attr.label_list(allow_empty = True, allow_files = [".arxml", ".cdd", ".dbc"], doc = "Inputfiles if inputfile update is executed"),
    "davinci_project_files": attr.label_list(allow_empty = True, allow_files = [".arxml", ".dcf", ".xml"], doc = "Project files if a project is modified"),
    "ocs_config_files": attr.label_list(allow_empty = True, allow_files = [".json"], doc = "The ocs plugin json files from ocs home directory"),
    "private_is_windows": attr.bool(mandatory = True, doc = "Set automatically for the correct OS"),
    "result": attr.output_list(mandatory = True, doc = "OCS run output files"),
}

ocs_def = rule(
    implementation = _ocs_impl,
    attrs = ocs_attrs,
    toolchains = [
        "@rules_davinci_developer//:toolchain_type",
        "@rules_cfg5//:toolchain_type",
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
