"""Simple external package vector bazel rules"""

package(default_visibility = ["//visibility:public"])

exports_files(glob(["**/*"]))

filegroup(
    name = "package",
    srcs = glob([
        "**/*",
    ]),
)

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)