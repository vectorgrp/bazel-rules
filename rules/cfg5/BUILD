load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    glob(
        ["*"],
    ),
)

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "rules",
    srcs = ["rules.bzl"],
    visibility = ["//visibility:public"],
    deps = ["//rules/common:create_davinci_tool_workspace"],
)

bzl_library(
    name = "toolchains",
    srcs = ["toolchains.bzl"],
    visibility = ["//visibility:public"],
)
