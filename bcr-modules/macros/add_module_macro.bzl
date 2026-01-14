"""A simple macro to build the whole module information for all versions and allow moving them into the correct folder in the registry"""

load("@rules_pkg//:mappings.bzl", "pkg_files")
load("@rules_pkg//:pkg.bzl", "pkg_zip")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("//bcr-modules/rules:defs.bzl", "metadata_json")

def _add_module_macro_impl(name, visibility, versions, **kwargs):
    # use the name and versions to get the correct targets that this should combine, can use any metadata_json attributes
    metadata_json(
        name = name + "_metadata.json",
        versions = versions,
        **kwargs
    )
    pkg_files_labels = [name + "_metadata.json"]

    # will go over the versions and the check the subpackages, naming is very important for this to work like it is, otherwise we would have to use labels directly.
    # makes it smoother to have both the label and the version as a string
    for version in versions:
        # files from each version will be prefixed with the version to make sure the metadata folder is correct.
        pkg_files(
            name = name + "_" + version + "_pkg_files",
            srcs = ["//bcr-modules/modules/" + name + "/" + version + ":" + name + "_" + version],
            prefix = version,
            visibility = visibility,
        )

        pkg_files_labels.append(name + "_" + version + "_pkg_files")

    # package the files in a zip, this can be replaced with other means, just decided it would be easier to use the existing rule for packaging
    # and add a binary target to unzip to the target directory
    pkg_zip(
        name = name,
        srcs = pkg_files_labels,
        compression_level = 9,
        mode = "0755",
        visibility = visibility,
    )

    # bazel run target to directly put the generated metadata information into  the vector-bazel-central-registry/modules folder in the repo
    sh_binary(
        name = name + ".add_to_repo",
        srcs = ["//tools:add_module.sh"],
        args = ["$(location @ape//ape:unzip)", "$(location " + name + ")", "vector-bazel-central-registry/modules/" + name],
        data = [name, "@ape//ape:unzip"],
        visibility = visibility,
    )

module_bcr_dir = macro(
    implementation = _add_module_macro_impl,
    inherit_attrs = metadata_json,
    attrs = {
        "versions": attr.string_list(doc = "Versions list to build the dependencies and correct metadata.json file.", mandatory = True, configurable = False),
    },
    finalizer = True,
)
