"""A simple macro to build upload and download targets for a given module version and urls"""

load("//bcr-modules:urls.bzl", "DEFAULT_DEV_GIT_UPLOAD_URL", "DEFAULT_PROD_GIT_UPLOAD_URL")

def _get_url(url, upload_module_name, version):
    # will set the correct default url for uploading to GitHub Releases
    if url in [DEFAULT_DEV_GIT_UPLOAD_URL, DEFAULT_PROD_GIT_UPLOAD_URL]:
        if upload_module_name == "" or version == "":
            fail("If the default url is used, upload_module_name and version need to be set.")
        # GitHub Releases URL pattern: https://github.com/vectorgrp/bazel-rules/releases/download/<module_name>/<version>/<module_name>.tar.gz
        # For staging: https://github.com/vectorgrp/bazel-rules/releases/download/staging/<module_name>/<version>/<module_name>.tar.gz
        return url + "/" + upload_module_name + "/" + version + "/" + upload_module_name + ".tar.gz"
    return url

def _upload_macro_impl(name, visibility, upload_module_name, version, archive, dev_github_upload_url, prod_github_upload_url, redeploy_if_exists):
    URLS = {
        # GitHub Releases URLs
        "upload.github_staging": _get_url(dev_github_upload_url, upload_module_name, version),
        "upload.github_prod": _get_url(prod_github_upload_url, upload_module_name, version),
    }

    for target in URLS.keys():
        # Add a convenience function to get moduel archive_override text
        native.sh_binary(
            name = target + "_get_archive_override",
            srcs = ["//tools:get_archive_override.sh"],
            args = [
                URLS[target],
                "$(location " + archive + ")",
            ],
            data = [archive],
            visibility = visibility,
        )

module_upload = macro(
    implementation = _upload_macro_impl,
    attrs = {
        "archive": attr.string(doc = "Module archive that should be uploaded.", mandatory = True, configurable = False),
        "dev_github_upload_url": attr.string(doc = "The staging/dev GitHub Releases url to upload the archive to.", mandatory = False, default = DEFAULT_DEV_GIT_UPLOAD_URL, configurable = False),
        "prod_github_upload_url": attr.string(doc = "The production GitHub Releases url to upload the archive to.", mandatory = False, default = DEFAULT_PROD_GIT_UPLOAD_URL, configurable = False),
        "redeploy_if_exists": attr.string(doc = "If True, will try to reupload the archive, even if it already exists at the target location.", mandatory = False, default = "false", configurable = False),
        "upload_module_name": attr.string(doc = "The name of that the module will have when using the default upload url", mandatory = False, default = "", configurable = False),
        "version": attr.string(doc = "The version of the module that is about to be uploaded", mandatory = False, default = "", configurable = False),
    },
    finalizer = True,
)
