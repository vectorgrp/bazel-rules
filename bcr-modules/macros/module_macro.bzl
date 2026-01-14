""""Macro to be able to create a generic Module setup"""

load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_pkg//:mappings.bzl", "pkg_files")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("//bcr-modules:urls.bzl", "DEFAULT_DEV_GIT_UPLOAD_URL", "DEFAULT_PROD_GIT_UPLOAD_URL")
load("//bcr-modules/rules:defs.bzl", "module_dir", "module_dot_bazel", "source_json")

def _module_macro_impl(
        name,
        visibility,
        module_version,
        build_file_tpl,
        srcs,
        third_party_prefix,
        url,
        pkg_files_targets,
        additional_dependencies,
        integrity,
        module_file):
    # Used as a workaround for packaging archives containing BUILD.bazel files, while the target for building that archive is defined in a BUILD.bazel file in the same location. Makes it easier to manage
    copy_file(
        name = name + "_BUILD_bazel",
        src = build_file_tpl,
        out = name + "/BUILD.bazel",
    )
    dev_archive_url = url
    prod_archive_url = url
    if url == "":
        # GitHub Releases URL pattern: .../download/staging/<module>/<version>/<module>.tar.gz
        dev_archive_url = DEFAULT_DEV_GIT_UPLOAD_URL + "/" + name + "/" + module_version + "/" + name + ".tar.gz"

        # GitHub Releases URL pattern: .../download/<module>/<version>/<module>.tar.gz
        prod_archive_url = DEFAULT_PROD_GIT_UPLOAD_URL + "/" + name + "/" + module_version + "/" + name + ".tar.gz"

    # used to package our module archive while at the same time setting the mode to 0755, this had to be done via pes-cd before.
    pkg_tar(
        name = name,
        srcs = [name + "_srcs", ":" + name + "_BUILD_bazel"] if len(pkg_files_targets) <= 0 else pkg_files_targets,
        extension = "tar.gz",
        mode = "0755",
        visibility = visibility,
    )

    # If the optional integrity attribute is set, the download will always be skipped (if files would have been downloaded)
    # Mainly used to reduce execution times and load times during local and CI runs.
    if integrity == "":
        if len(srcs) == 0 and len(pkg_files_targets) == 0:
            fail("If no srcs are provided, please add the integrity to be able to generate the module information.")

        if len(pkg_files_targets) <= 0:
            # pkg_files is used to make managing groups of files easier, especially when using pkg_zip afterwards, as this allows us to utilize things like prefixes.
            pkg_files(
                name = name + "_srcs",
                srcs = srcs,
                prefix = third_party_prefix,
                visibility = visibility,
            )

        # utilize helper rule to create the source.json, uses the archive to calculate the sha256
        source_json(
            name = name + "_source.json",
            archive_url = select({
                "//:build_prod_modules": prod_archive_url,
                "//conditions:default": dev_archive_url,
            }),
            module_archive = ":" + name,
        )

    else:
        # empty filegroup to ensure that nothing will depend on this if the integrity is already set
        pkg_files(
            name = name + "_srcs",
            srcs = srcs,
            prefix = third_party_prefix,
            visibility = visibility,
        )

        # utilize helper rule to create the source.json, uses the given integrity for the sha256
        source_json(
            name = name + "_source.json",
            archive_url = select({
                "//:build_prod_modules": prod_archive_url,
                "//conditions:default": dev_archive_url,
            }),
            integrity = integrity,
        )

    if not module_file:
        # utilize helper rule to create the MODULE.bazel file for the module metadata
        mdb_name = name + "_MODULE.bazel"
        module_dot_bazel(
            name = mdb_name,
            module_name = name,
            module_version = module_version,
            additional_dependencies = additional_dependencies,
        )
    else:
        mdb_name = module_file.name

    # use pkg_files to make collecting and setting up files easier
    pkg_files(
        name = name + "_" + module_version + "_files",
        srcs = [
            mdb_name,
            ":" + name + "_source.json",
        ],
        visibility = visibility,
    )

    # create the directory containing the metadata for a singular module version
    # mostly used for the add_module_macro to reference the complete module directory.
    module_dir(
        name = name + "_" + module_version,
        pkg_files = [
            ":" + name + "_" + module_version + "_files",
        ],
    )

module = macro(
    implementation = _module_macro_impl,
    attrs = {
        "module_version": attr.string(doc = "The version of the module metadata that is to be created.", mandatory = True, configurable = False),
        "url": attr.string(doc = "The url of the module archive.", mandatory = False, configurable = False),
        "integrity": attr.string(doc = "Optional integrity string to replace the downloaded files with. Saves the expensive download.", mandatory = False, configurable = False, default = ""),
        "third_party_prefix": attr.string(doc = "Can be used to prefix the packaged files in the module archive with.", mandatory = False, configurable = False, default = ""),
        "srcs": attr.label_list(doc = "List of files that should be packaged in the module archive.", mandatory = False, configurable = False, allow_files = True, default = []),
        "build_file_tpl": attr.label(doc = "Optional replacement of the default BUILD.bazel.tpl file that will be packaged in the module archive.", mandatory = False, default = Label("//bcr-modules:BUILD.bazel.tpl"), allow_single_file = True),
        "pkg_files_targets": attr.label_list(doc = "Optional replacement for the default pkg_files target to be able to use the macro while having more control of the file structure in the archive", mandatory = False, default = [], configurable = False),
        "additional_dependencies": attr.string_list(mandatory = False, allow_empty = True, default = [], doc = "Additional dependencies that will be added to the MODULE.bazel file being generated"),
        "module_file": attr.label(doc = "Optional reference to a custom module_dot_bazel target.", mandatory = False, allow_single_file = True, configurable = False, default = None),
    },
    finalizer = True,
)
