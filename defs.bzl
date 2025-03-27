"""Vector-Bazel-Rules
"""
load("//rules/cfg5:rules.bzl", _cfg5_generate_rt = "cfg5_generate_rt", _cfg5_generate_rt_workspace = "cfg5_generate_rt_workspace", _cfg5_generate_vtt = "cfg5_generate_vtt", _cfg5_generate_vtt_workspace = "cfg5_generate_vtt_workspace", _start_cfg5_windows = "start_cfg5_windows")
load("//rules/cfg5:toolchains.bzl", _cfg5_toolchain = "cfg5_toolchain")

# DaVinci Configurator 5 rules
start_cfg5_windows = _start_cfg5_windows
cfg5_generate_vtt_workspace = _cfg5_generate_vtt_workspace
cfg5_generate_rt_workspace = _cfg5_generate_rt_workspace
cfg5_generate_vtt = _cfg5_generate_vtt
cfg5_generate_rt = _cfg5_generate_rt

# Toolchain rules
cfg5_toolchain = _cfg5_toolchain

