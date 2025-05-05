"""Rules for dvteam"""

load("//rules/common:create_davinci_tool_workspace.bzl", "create_davinci_tool_workspace")

_DVTEAM_TEMPLATE_ENV_VAR_LINUX = """
export GRADLE_USER_HOME=$PWD/{gradle_properties_folder} &&
export DEVELOPER_PATH=$PWD/{developer_path}/DEVImEx/bin &&
export VTT_PATH=$PWD/{vtt_path} &&
export SIP=$PWD/{sip_folder} &&
export ROOT_CONFIG=$PWD/{workspace_path} &&
export EXECROOT=$PWD &&
export DOTNET_ROOT=$PWD/{dotnet_path} && 
"""

_DVTEAM_TEMPLATE_ENV_VAR_WINDOWS = """
$env:GRADLE_USER_HOME="$PWD/{gradle_properties_folder}";
$env:DEVELOPER_PATH="{developer_path}";
$env:VTT_PATH="{vtt_path}";
$env:SIP="$PWD/{sip_folder}";
$env:ROOT_CONFIG="$PWD/{workspace_path}";
$env:EXECROOT=$PWD; 
"""

# the copy is necessary because the vtt path will be updated with dvteam and this is usually not allowed in the bazel output folder
_DVTEAM_TEMPLATE_LINUX = """
sudo chmod 777 $PWD/{exec_folder}/{workspace_prefix}/{dpa_basename}.dpa &&
{gradle_path} -Dorg.gradle.project.buildDir=$PWD/{gradle_exec_folder} -Pcom.vector.dvt.ci.config=$PWD/{wfconfig} clean -b {gradle_file_path} &&
{gradle_path} -Dorg.gradle.project.buildDir=$PWD/{gradle_exec_folder} -Pcom.vector.dvt.ci.config=$PWD/{wfconfig} {jks_value} --no-build-cache -b {gradle_file_path} {task} {dvteam_args}
"""

# template for running dvteam under windows and with bazel, needs specific paths to be set
_DVTEAM_TEMPLATE_WINDOWS = 'Set-ItemProperty -Path "$PWD/{exec_folder}/{workspace_prefix}/{dpa_basename}.dpa" -Name IsReadOnly -Value $false; start-process "./{gradle_path}" -ArgumentList "--no-daemon -Dorg.gradle.project.buildDir=$PWD/{gradle_exec_folder} -Pcom.vector.dvt.ci.config=$PWD/{wfconfig} clean -b {gradle_file_path}" -Wait -NoNewWindow -RedirectStandardError "$PWD/{exec_folder}/{workspace_prefix}/gradle.errout.log" -RedirectStandardOutput "$PWD/{exec_folder}/{workspace_prefix}/gradle.output.log"; start-process "./{gradle_path}" -ArgumentList "--no-daemon -Dorg.gradle.project.buildDir=$PWD/{gradle_exec_folder} -Pcom.vector.dvt.ci.config=$PWD/{wfconfig} {jks_value} -b {gradle_file_path} {task} {dvteam_args}" -Wait -NoNewWindow -RedirectStandardError "$PWD/{exec_folder}/{workspace_prefix}/gradle.errout.log" -RedirectStandardOutput "$PWD/{exec_folder}/{workspace_prefix}/gradle.output.log"'

def _dvteam_impl(ctx):
    # simple dvteam workspace dictionary that is created for further use
    dvt_workspace = create_davinci_tool_workspace(ctx, workspace_name = ctx.label.name + "_dvt_workspace", addtional_workspace_files = [ctx.file.dpa_file], is_windows = ctx.attr.private_is_windows, config_files = ctx.files.config_files, config_folders = ctx.attr.config_folders)

    info_davinci_developer = ctx.toolchains["//rules/davinci_developer:toolchain_type"]
    info_gradle = ctx.toolchains["//rules/gradle:toolchain_type"]
    tools = []

    if not info_davinci_developer.davinci_developer_label and not info_davinci_developer.davinci_developer_path:
        fail("Developer toolchain is needed for DaVinci Team and needs either one of davinci_developer_label or davinci_developer_path defined")
    developer_path = info_davinci_developer.davinci_developer_label.path if info_davinci_developer.davinci_developer_label else info_davinci_developer.davinci_developer_path

    if info_davinci_developer.davinci_developer_label:
        tools.append(info_davinci_developer.davinci_developer_label)

    if not info_gradle.gradle_label and not info_gradle.gradle_path:
        fail("Gradle toolchain is needed for DaVinci Team and needs either one of gradle_label or gradle_path defined")
    gradle_path = info_gradle.gradle_label.path if info_gradle.gradle_label else info_gradle.gradle_path

    if info_gradle.gradle_label:
        tools.append(info_gradle.gradle_label)
    if info_gradle.gradle_properties:
        tools.append(info_gradle.gradle_properties)

    inputs = ctx.files.app_package_sources + ctx.files.config_files + [ctx.file.dpa_file] + [ctx.file.gradle_file] + ctx.files.global_instruction_files + ctx.files.custom_scripts

    workspace_prefix = dvt_workspace.workspace_prefix
    dpa_copy = dvt_workspace.addtional_workspace_files[0]
    dpa_basename = dpa_copy.basename.split(".")[0]

    # find path to BUILD file
    build_path = ctx.label.package

    # folder where gradle shall be executed, currently hardcoded execroot
    exec_folder = ctx.bin_dir.path + "/" + build_path
    gradle_exec_folder = ctx.bin_dir.path + "/" + build_path + "/" + ctx.label.name
    sip_folder = Label(ctx.attr.sip.label).workspace_root
    workspace_path = dpa_copy.dirname

    vtt_make_path = ""
    info_vtt = ctx.toolchains["//rules/vtt:toolchain_type"]
    if info_vtt and (ctx.toolchains["//rules/vtt:toolchain_type"].vtt_make_label or ctx.toolchains["//rules/vtt:toolchain_type"].vtt_make_path):
        vtt_make_path = info_vtt.vtt_make_label.dirname if info_vtt.vtt_make_label else info_vtt.vtt_make_path
        if vtt_make_path == info_vtt.vtt_make_path:
            vtt_make_path = info_vtt.vtt_make_path.split("/Exec64/VttMake.exe")[0]

        if info_vtt.vtt_make_label:
            tools.append(info_vtt.vtt_make_label)

    info_cfg5 = ctx.toolchains["//rules/cfg5:toolchain_type"]
    tools.append(info_cfg5.cfg5cli_path)

    # Dotnet path for developer in linux
    dotnet_path = ""
    if ctx.attr.private_is_windows == False:
        dotnet = ctx.toolchains["@rules_dotnet//dotnet:toolchain_type"]
        dotnet_path = dotnet.dotnetinfo.runtime_path.split("/dotnet")[0]
        tools.extend(dotnet.dotnetinfo.runtime_files)

    # Setup OpenJDK
    if ctx.attr.java_keystore_file:
        jks_value = "-Djavax.net.ssl.trustStore={} -Djavax.net.ssl.trustStorePassword={}".format(
            ctx.file.java_keystore_file.path,
            ctx.attr.java_keystore_password,
        )
    else:
        jks_value = ""

    java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:toolchain_type"]
    java_home = java_toolchain.java.java_runtime.java_home

    # prepare dvt_template
    dvt_template = _DVTEAM_TEMPLATE_WINDOWS if ctx.attr.private_is_windows else _DVTEAM_TEMPLATE_LINUX
    gradle_cmd = dvt_template.format(
        gradle_path = gradle_path,
        exec_folder = exec_folder,
        gradle_exec_folder = gradle_exec_folder,
        wfconfig = ctx.file.wfconfig.path,
        gradle_file_path = ctx.file.gradle_file.path,
        task = ctx.attr.task,
        dvteam_args = " ".join(ctx.attr.dvteam_args),
        workspace_prefix = workspace_prefix,
        dpa_basename = dpa_basename,
        jks_value = jks_value,
    )

    if info_gradle.gradle_properties.path and not ctx.attr.private_is_windows:
        gradle_cmd = _DVTEAM_TEMPLATE_ENV_VAR_LINUX.format(
            gradle_properties_folder = "/".join(info_gradle.gradle_properties.path.split("/")[:-1]),
            developer_path = developer_path.split("/DEVImEx/bin")[0],
            vtt_path = vtt_make_path,
            sip_folder = sip_folder,
            workspace_path = workspace_path,
            dotnet_path = dotnet_path,
        ) + gradle_cmd

    if info_gradle.gradle_properties.path and ctx.attr.private_is_windows:
        gradle_cmd = _DVTEAM_TEMPLATE_ENV_VAR_WINDOWS.format(
            gradle_properties_folder = "/".join(info_gradle.gradle_properties.path.split("/")[:-1]),
            developer_path = developer_path,
            vtt_path = vtt_make_path,
            sip_folder = sip_folder,
            workspace_path = workspace_path,
        ) + gradle_cmd

    # use powershell for the windows run of dvt instead
    if ctx.attr.private_is_windows:
        ctx.actions.run(
            mnemonic = "dvteamWindows",
            executable = "powershell.exe",
            progress_message = "Executing DVTeam @ %s" % ctx.file.gradle_file.path,
            tools = tools,
            arguments = [gradle_cmd],
            env = {
                "OS": "Windows_NT",
                "windir": "C:\\Windows",
                "SystemRoot": "C:\\Windows",
                "JAVA_HOME": java_home,
            },
            inputs = inputs + dvt_workspace.files + [ctx.file.wfconfig] + dvt_workspace.addtional_workspace_files + ctx.attr.sip.files.to_list(),
            outputs = ctx.outputs.results,
        )

    else:
        ctx.actions.run_shell(
            mnemonic = "dvteamLinux",
            progress_message = "Executing DVTeam @ %s" % ctx.file.gradle_file.path,
            tools = tools,
            command = gradle_cmd,
            inputs = inputs + dvt_workspace.files + [ctx.file.wfconfig] + dvt_workspace.addtional_workspace_files + ctx.attr.sip.files.to_list(),
            outputs = ctx.outputs.results,
        )

    return [
        DefaultInfo(files = depset(ctx.outputs.results)),
    ]

dvteam_attrs = {
    "dvteam_args": attr.string_list(doc = "The args for the actual dvteam run"),
    "gradle_file": attr.label(mandatory = True, allow_single_file = True, doc = "the build.gradle to run dvteam with"),
    "task": attr.string(mandatory = True, doc = "The dvteam task that will be run"),
    "app_package_sources": attr.label_list(doc = "the additional app package sources that should be integrated"),
    "results": attr.output_list(mandatory = True, doc = "The dvteam run output config files"),
    "wfconfig": attr.label(mandatory = True, allow_single_file = [".json"], doc = "The prepared wfconfig file, can use substituted variables for DEVELOPER_PATH, VTT_PATH, EXECROOT and ROOT_CONFIG these will be filled out by bazel according to the toolchain info that is given"),
    "config_files": attr.label_list(allow_files = [".arxml", ".dcf", ".dvg", ".xml", ".dpa", ".zip", ".a2l", ".cdd"], doc = "The expected output files of DaVinci Team"),
    "global_instruction_files": attr.label_list(allow_files = [".json"], doc = "List of global instruction files. Depending on the instruction type, global instructions may be an addition to or have precedence over App Package specific instructions."),
    "custom_scripts": attr.label_list(allow_files = [".dvgroovy"], doc = "Costum Scipts, that can be exectued in dvteam"),
    "dpa_file": attr.label(mandatory = True, allow_single_file = [".dpa"], doc = "dpa file to use for the dvteam run"),
    "sip": attr.label(mandatory = True, doc = "sip location to mark it as a dependency, as it the sip is needed for dvteam execution"),
    "private_is_windows": attr.bool(mandatory = True, doc = "Set automatically for the correct OS"),
    # "A List of the folders where the config files reside, this cannot be detected automatically, as only the current package can be resolved elegantly"
    "config_folders": attr.string_list(doc = "(Optional) List of config folders that the path will be checked for in each file to create a nested Config folder structure, default is [\"Config\"]", default = ["Config"]),
    # Attributes to add a java keystore to the used jdk toolchain
    "java_keystore_file": attr.label(mandatory = False, allow_single_file = True, doc = "Java KeyStore file with vector certificates."),
    "java_keystore_password": attr.string(mandatory = False, default = "changeit", doc = "Java KeyStore password. Default value is changeit"),
}

dvteam_def = rule(
    implementation = _dvteam_impl,
    attrs = dvteam_attrs,
    doc = "DaVinciTeam rule to run gradle in the background and add the output to bazel",
    toolchains = [
        "//rules/davinci_developer:toolchain_type",
        "//rules/gradle:toolchain_type",
        "//rules/cfg5:toolchain_type",
        "@bazel_tools//tools/jdk:toolchain_type",
        config_common.toolchain_type("@rules_dotnet//dotnet:toolchain_type", mandatory = False),
        config_common.toolchain_type("//rules/vtt:toolchain_type", mandatory = False),
    ],
)

def dvteam(name, **kwargs):
    """Wraps the dvteam with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        **kwargs: All of the attrs of the dvteam rule

    Returns:
        A dvteam_def rule that contains the actual implementation
    """
    dvteam_def(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
