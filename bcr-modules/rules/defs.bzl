"""Simple export file to make importing rules a bit easier"""

load("//bcr-modules/rules:metadata_json.bzl", _metadata_json = "metadata_json")
load("//bcr-modules/rules:module.bzl", _module_dir = "module_dir")
load("//bcr-modules/rules:module_dot_bazel.bzl", _module_dot_bazel = "module_dot_bazel")
load("//bcr-modules/rules:source_json.bzl", _source_json = "source_json")

source_json = _source_json
module_dot_bazel = _module_dot_bazel
metadata_json = _metadata_json
module_dir = _module_dir
