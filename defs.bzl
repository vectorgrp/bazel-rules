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

