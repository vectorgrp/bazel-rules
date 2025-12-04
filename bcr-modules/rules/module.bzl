"""This rule is used to build up the correct module_info, this rules output is then used to build the whole module folder"""

load("@rules_pkg//pkg:providers.bzl", "PackageFilesInfo")

def _module_dir_impl(ctx):
    package_files_info = [info[PackageFilesInfo] for info in ctx.attr.pkg_files]
    dest_src_maps = [pkg_files.dest_src_map for pkg_files in package_files_info]

    module_dir_path = ""

    if ctx.attr.pkg_path != "":
        module_dir_path = ctx.attr.pkg_path
    else:
        if len(ctx.label.package.split("/modules/")) < 2:
            fail("Either provide a pkg_path or put the target for this rule inside a modules folder to allow automatic naming")
        module_dir_path = ctx.label.package.split("/modules/")[1]

    output = []

    for dest_src_map in dest_src_maps:
        for dest_src_map_key in dest_src_map.keys():
            new_file_path = dest_src_map[dest_src_map_key].path.split(module_dir_path + "/")[1]
            input_file = dest_src_map[dest_src_map_key]
            output_file = ctx.actions.declare_file("module_info/" + new_file_path)
            output.append(output_file)

            ctx.actions.run(
                inputs = [input_file],
                outputs = [output_file],
                executable = ctx.executable.cp,
                arguments = [input_file.path, output_file.path],
            )

    return DefaultInfo(
        files = depset(output),
    )

module_dir = rule(
    implementation = _module_dir_impl,
    attrs = {
        "pkg_path": attr.string(
            doc = "Optional path to where this module dir should created to, this disables the automatic directory structure that needs one to follow the /modules/ path",
            mandatory = False,
            default = "",
        ),
        "pkg_files": attr.label_list(
            doc = "The pkg_files is used to create the actual dir that will be checked in the actual registry, the PackageFilesInfo  is used. see: https://github.com/bazelbuild/rules_pkg/blob/main/pkg/providers.bzl for more information",
            providers = [PackageFilesInfo],
            mandatory = True,
        ),
        "cp": attr.label(
            doc = "The cp executable",
            executable = True,
            default = Label("@ape//ape:cp"),
            mandatory = False,
            cfg = "exec",
        ),
    },
)
