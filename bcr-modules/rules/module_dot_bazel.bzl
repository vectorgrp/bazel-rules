"""Simple helper rule to create a MODULE.bazel rule for a module version that you want to release"""

_MODULE_DOT_BAZEL_CMD = """
set -euo pipefail
# Create the main folder

cat <<EOL > {module_dot_bazel_path}
module(
    name = "{module_name}",
    version = "{module_version}",
    compatibility_level = {compatibility_level},
)

EOL
"""

_APPEND_ADDITIONAL_DEPENDENCY_CMD = """
echo 'bazel_dep(name = "{name}", version = "{version}")' >> {module_dot_bazel_path}
"""

_APPEND_EXTRA_CONENT_CMD = """
echo '\n{extra_content}\n' >> {module_dot_bazel_path}
"""

def _module_dot_bazel_impl(ctx):
    module_dot_bazel_file = ctx.actions.declare_file("MODULE.bazel")
    MODULE_DOT_BAZEL_CMD = _MODULE_DOT_BAZEL_CMD.format(
        module_dot_bazel_path = module_dot_bazel_file.path,
        module_name = ctx.attr.module_name,
        module_version = ctx.attr.module_version,
        compatibility_level = ctx.attr.compatibility_level,
    )
    for additional_dependency in ctx.attr.additional_dependencies:
        if len(additional_dependency.split("@")) != 2:
            fail("Please follow the naming convention of additional dependencies by providing them as <name>@<version>")

        name = additional_dependency.split("@")[0]
        version = additional_dependency.split("@")[1]
        MODULE_DOT_BAZEL_CMD += _APPEND_ADDITIONAL_DEPENDENCY_CMD.format(name = name, version = version, module_dot_bazel_path = module_dot_bazel_file.path)

    if len(ctx.attr.extra_content) > 0:
        MODULE_DOT_BAZEL_CMD += _APPEND_EXTRA_CONENT_CMD.format(extra_content = ctx.attr.extra_content, module_dot_bazel_path = module_dot_bazel_file.path)

    ctx.actions.run_shell(
        outputs = [module_dot_bazel_file],
        command = MODULE_DOT_BAZEL_CMD,
    )
    return [DefaultInfo(files = depset([module_dot_bazel_file]))]

module_dot_bazel = rule(
    implementation = _module_dot_bazel_impl,
    attrs = {
        "module_name": attr.string(doc = "The name of the module being created", mandatory = True, default = ""),
        "module_version": attr.string(doc = "The version of the module being created", mandatory = True, default = ""),
        "additional_dependencies": attr.string_list(doc = "Please enter dependencies in the form of <name>@<version>", mandatory = False, default = []),
        "compatibility_level": attr.string(doc = "Compatibility level of the module", mandatory = False, default = "1"),
        "extra_content": attr.string(doc = "Additional content for the module.bazel file", mandatory = False, default = ""),
    },
)
