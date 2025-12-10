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

"""Defines DaVinci Project Rules and Providers"""

DaVinciProjectInfo = provider(
    doc = "Provides a DaVinci Project Info",
    fields = {
        "project_zip": "The path to the DaVinci project zip file",
        "dpa_name": "Path inside the zip to the DPA file",
    },
)

def _create_cfg5_gui_run_conf(ctx, project_name, project_zip, dpa_name):
    """ Get all information from ctx to build cfg5 gui executable and collect all runfiles """
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    wrapper_script = ctx.actions.declare_file(ctx.attr.name + (".bat" if is_windows else ".sh"))
    pydpa_call_config = ctx.actions.declare_file("pydpa_call_config.manifest")

    # Create wrapper script
    if is_windows:
        template = ctx.file._pydpa_script_template_windows
    else:
        template = ctx.file._pydpa_script_template_linux

    ctx.actions.expand_template(
        template = template,
        output = wrapper_script,
        is_executable = True,
        substitutions = {
            "executable": ctx.executable._pydpa.short_path,
            "call_config_file": pydpa_call_config.short_path,
        },
    )

    runfiles_cfg5_base_dir = ctx.attr.configurator5[DefaultInfo].files.to_list()[0].short_path
    runfiles_cfg5_base_dir = runfiles_cfg5_base_dir[:runfiles_cfg5_base_dir.rindex("/")]

    pydpa_call_config_content = "\n".join([
        "open",
        "--name",
        project_name,
        "--zip",
        project_zip.short_path,
        "--dpa_name",
        dpa_name,
        "--output",
        "somewhere",
        "--cfg5_base_dir",
        runfiles_cfg5_base_dir,
        "--verbose",
    ])

    ctx.actions.write(
        output = pydpa_call_config,
        content = pydpa_call_config_content,
    )

    # Create runfiles
    transitive_runfiles = [ctx.attr._pydpa.default_runfiles, ctx.attr.configurator5[DefaultInfo].default_runfiles]
    runfiles = ctx.runfiles(
        files = [ctx.executable._pydpa, pydpa_call_config, project_zip] + ctx.attr.configurator5[DefaultInfo].files.to_list(),
        collect_default = True,
    ).merge_all(transitive_runfiles)

    return wrapper_script, runfiles

def _dpa_project_impl(ctx):
    """Creates a DaVinci project from a given DPA file and configures the project folder structure."""

    dpa_file = ctx.file.dpa_file
    project_name = ctx.attr.name

    configurator5 = ctx.files.configurator5
    cfg5_base_dir = configurator5[0].dirname

    out_project_zip = ctx.actions.declare_file(ctx.attr.name + ".zip")

    args = ctx.actions.args()
    args.add("create_zip")
    args.add("--name", project_name)
    args.add("--dpa", dpa_file)
    args.add("--cfg5_base_dir", cfg5_base_dir)
    args.add("--output", out_project_zip)
    args.add("--verbose")

    ctx.actions.run(
        inputs = [dpa_file] + configurator5,
        outputs = [out_project_zip],
        executable = ctx.executable._pydpa,
        arguments = [args],
        mnemonic = "DaVinciProject",
        progress_message = "Creating DaVinci project from DPA file: {}".format(dpa_file.basename),
    )

    gui_exec, gui_runfiles = _create_cfg5_gui_run_conf(ctx, project_name, out_project_zip, dpa_file.basename)

    return [
        DefaultInfo(
            executable = gui_exec,
            runfiles = gui_runfiles,
        ),
        DaVinciProjectInfo(
            project_zip = out_project_zip,
            dpa_name = dpa_file.basename,
        ),
    ]

dpa_project = rule(
    implementation = _dpa_project_impl,
    attrs = {
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
        "_pydpa": attr.label(
            default = Label("//private/pydpa"),
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "_pydpa_lib": attr.label(
            default = Label("//private/pydpa:pydpa_lib"),
        ),
        "_pydpa_script_template_windows": attr.label(
            allow_single_file = [".tpl"],
            default = Label("//:templates/pydpa_script_windows.tpl"),
        ),
        "_pydpa_script_template_linux": attr.label(
            allow_single_file = [".tpl"],
            default = Label("//:templates/pydpa_script_linux.tpl"),
        ),
        "dpa_file": attr.label(
            allow_single_file = [".dpa"],
            doc = "DaVinci project file",
            mandatory = True,
        ),
        "configurator5": attr.label(
            allow_files = True,
            doc = "Configurator 5 target of a MSRC SIP",
        ),
    },
    toolchains = [
        "@rules_python//python:toolchain_type",
    ],
    executable = True,
)

def _dpa_generate_impl(ctx):
    """ Uses Cfg5 to generate the given DPA Project. """
    project_name = ctx.attr.name

    configurator5 = ctx.files.configurator5
    cfg5_base_dir = configurator5[0].dirname

    project_zip = ctx.attr.project[DaVinciProjectInfo].project_zip
    project_zip_dpa_name = ctx.attr.project[DaVinciProjectInfo].dpa_name

    generate_input_files = []
    generate_input_files.append(project_zip)
    generate_input_files.extend(configurator5)

    generate_output = ctx.actions.declare_directory(project_name)

    generate_args = ctx.actions.args()
    generate_args.add("generate")
    generate_args.add("--name", project_name)
    generate_args.add("--zip", project_zip.path)
    generate_args.add("--dpa_name", project_zip_dpa_name)
    generate_args.add("--output", generate_output.path)
    generate_args.add("--cfg5_base_dir", cfg5_base_dir)
    generate_args.add("--verbose")
    generate_args.add_all(ctx.attr.include_modules, before_each = "--modules_to_include")
    generate_args.add_all(ctx.attr.exclude_modules, before_each = "--modules_to_exclude")

    ctx.actions.run(
        inputs = depset(generate_input_files),
        outputs = [generate_output],
        executable = ctx.executable._pydpa,
        arguments = [generate_args],
        mnemonic = "DaVinciGenerate",
        progress_message = "Generate DaVinci project : {}".format(project_zip.basename),
    )

    create_zip_output_zip = ctx.actions.declare_file(ctx.attr.name + ".zip")

    create_zip_args = ctx.actions.args()
    create_zip_args.add("create_zip")
    create_zip_args.add("--name", project_name)
    create_zip_args.add("--dpa", generate_output.path + "/" + project_zip_dpa_name)
    create_zip_args.add("--cfg5_base_dir", cfg5_base_dir)
    create_zip_args.add("--output", create_zip_output_zip)
    create_zip_args.add("--verbose")

    ctx.actions.run(
        inputs = [generate_output],
        outputs = [create_zip_output_zip],
        executable = ctx.executable._pydpa,
        arguments = [create_zip_args],
        mnemonic = "DaVinciProject",
        progress_message = "Creating DaVinci project zip: {}".format(project_zip_dpa_name),
    )

    return [
        DefaultInfo(
            files = depset([generate_output]),
        ),
        DaVinciProjectInfo(
            project_zip = create_zip_output_zip,
            dpa_name = project_zip_dpa_name,
        ),
    ]

dpa_generate = rule(
    implementation = _dpa_generate_impl,
    attrs = {
        "_pydpa": attr.label(
            default = Label("//rules/davinci_project/pydpa"),
            allow_files = True,
            doc = "The DPA parser tool for DaVinci projects",
            executable = True,
            cfg = "exec",
        ),
        "project": attr.label(
            providers = [DaVinciProjectInfo],
            doc = "The DaVinci project",
        ),
        "include_modules": attr.string_list(
            default = [],
            doc = "List of modules to include in generation",
        ),
        "exclude_modules": attr.string_list(
            default = [],
            doc = "List of modules to exclude from generation",
        ),
        "configurator5": attr.label(
            allow_files = True,
            doc = "Configurator 5 target of a MSRC SIP",
        ),
    },
)
