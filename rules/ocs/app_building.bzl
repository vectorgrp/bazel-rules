"""This rule builds an uber jar file, by copying and zipping the jar files provided by bazel in the correct way for the configurator 5"""

load("@bazel_skylib//lib:paths.bzl", "paths")

_LINUX_CMD = """
        # create jar_dir
        {mkdir} -p {jar_dir}
        # deploy_src needs to be extracted and modified
        {unzip} {deploy_src} -d {temp_dir}
        # additional_libs are imported jars which need to be copied to correct location
        {cp} {additional_libs} {jar_dir}
        # rename copied jar files
        for file in {jar_dir}/processed_*; do
            # Remove the "processed_" prefix
            new_file=$(basename "$file" | sed 's/^processed_//')
            {mv} "$file" "{jar_dir}/$new_file"
        done
        # remove now unnecessary folders
        {rm} -rf {temp_dir}/com {temp_dir}/server {temp_dir}/org {temp_dir}/kotlin {temp_dir}/kotlinx
        # rezip tempdir
        {mv} {temp_dir} "temp_to_zip_{this}"
        pushd "temp_to_zip_{this}"
        ../{zip} -r ../{output} ./*
        popd
        {mv} "temp_to_zip_{this}" {temp_dir}
        """

_WINDOWS_CMD = """
        # Create jar_dir
        New-Item -ItemType Directory -Force -Path {jar_dir}
        # Rename the .jar file to .zip
        $zipFile = [System.IO.Path]::ChangeExtension("{deploy_src}", ".zip")
        Move-Item -Path {deploy_src} -Destination $zipFile -Force
        # Unzip the file
        Expand-Archive -Path $zipFile -DestinationPath {temp_dir}
        # Remove unnecessary folders
        Remove-Item -Recurse -Force -Path "{temp_dir}\\com", "{temp_dir}\\server", "{temp_dir}\\org", "{temp_dir}\\kotlin", "{temp_dir}\\kotlinx"
        # Copy additional libs and remove "processed_" prefix
        "{additional_libs}" -split ' ' | ForEach-Object {{
            $newFileName = [System.IO.Path]::GetFileName($_) -replace '^processed_', ''
            Copy-Item -Path $_ -Destination (Join-Path -Path {jar_dir} -ChildPath $newFileName)
        }}
        # Rezip tempdir and change name to .jar
        Move-Item -Path {temp_dir} -Destination "temp_to_zip_{this}" -Force
        Push-Location "temp_to_zip_{this}"
        Start-Process -FilePath "{sevenzip_dir}\\7z.exe" -ArgumentList "a -tzip ..\\{output} .\\*" -Wait
        Pop-Location
        Move-Item -Path "temp_to_zip_{this}" -Destination {temp_dir} -Force
        """

def _create_ocs_app_deploy_impl(ctx):
    template = _WINDOWS_CMD if ctx.attr.private_is_windows else _LINUX_CMD
    deploy_src = ctx.file.deploy_src
    additional_libs = ctx.files.additional_libs

    # Create a list of additional_libs paths
    additional_libs_paths = " ".join([lib.path for lib in additional_libs])

    jar_file = ctx.actions.declare_file(ctx.attr.jar_file)
    this = ctx.label.name
    temp_dir = ctx.actions.declare_directory(ctx.label.name + "_temp_dir")
    jar_dir = paths.join(temp_dir.path, "jars")

    if ctx.attr.private_is_windows:
        info_sevenzip_dir = ctx.toolchains["//rules/ocs:toolchain_type"]

        if not info_sevenzip_dir.sevenzip_dir:
            fail("7z is needed under Windows")
        sevenzip_dir = info_sevenzip_dir.sevenzip_dir

        cmd = template.format(
            temp_dir = temp_dir.path,
            jar_dir = jar_dir,
            deploy_src = deploy_src.path,
            additional_libs = additional_libs_paths,
            output = jar_file.path,
            this = this,
            sevenzip_dir = sevenzip_dir,
        )
        ctx.actions.run(
            executable = "powershell.exe",
            arguments = [cmd],
            env = {
                "OS": "Windows_NT",
                "windir": "C:\\Windows",
                "SystemRoot": "C:\\Windows",
            },
            use_default_shell_env = True,
            inputs = [deploy_src] + additional_libs,
            outputs = [jar_file, temp_dir],
        )

    else:
        zip_tool = ctx.executable._zip
        unzip_tool = ctx.executable._unzip
        mkdir_tool = ctx.executable._mkdir
        rm_tool = ctx.executable._rm
        cp_tool = ctx.executable._cp
        mv_tool = ctx.executable._mv
        cmd = template.format(
            temp_dir = temp_dir.path,
            jar_dir = jar_dir,
            deploy_src = deploy_src.path,
            additional_libs = additional_libs_paths,
            output = jar_file.path,
            zip = zip_tool.path,
            unzip = unzip_tool.path,
            mkdir = mkdir_tool.path,
            rm = rm_tool.path,
            cp = cp_tool.path,
            mv = mv_tool.path,
            this = this,
        )
        ctx.actions.run_shell(
            inputs = [deploy_src] + additional_libs,
            outputs = [jar_file, temp_dir],
            command = cmd,
            tools = [zip_tool, unzip_tool, mkdir_tool, rm_tool, cp_tool, mv_tool],
        )

    return [DefaultInfo(files = depset([jar_file]))]

create_ocs_app_deploy_rule_internal = rule(
    implementation = _create_ocs_app_deploy_impl,
    attrs = {
        "private_is_windows": attr.bool(mandatory = True),
        "deploy_src": attr.label(allow_single_file = True, doc = "bazel deploy target of jar file"),
        "additional_libs": attr.label_list(allow_files = True, doc = "additional dependencies as maven targets"),
        "jar_file": attr.string(mandatory = True, doc = "name of output jar file"),
        "_zip": attr.label(
            default = Label("@ape//ape:zip"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_unzip": attr.label(
            default = Label("@ape//ape:unzip"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_mkdir": attr.label(
            default = Label("@ape//ape:mkdir"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_rm": attr.label(
            default = Label("@ape//ape:rm"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_cp": attr.label(
            default = Label("@ape//ape:cp"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_mv": attr.label(
            default = Label("@ape//ape:mv"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = [
        config_common.toolchain_type("//rules/ocs:toolchain_type", mandatory = False),
    ],
)

def create_ocs_app_deploy_rule(name, **kwargs):
    """Wraps the create_ocs_app_deploy_rule_internal with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        **kwargs: All of the attrs of the create_ocs_app_deploy_rule_internal rule

    Returns:
        A create_ocs_app_deploy_rule_internal rule that contains the actual implementation
    """
    create_ocs_app_deploy_rule_internal(
        name = name,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
