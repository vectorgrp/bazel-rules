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

"""Public entry point for cfg5_generate"""

# load("@rules_vtt//:toolchains.bzl", "generate_tools_vtt")
load("private/generate.bzl", "cfg5_generate_workspace_cc_attrs", "cfg5_generate_workspace_cc_impl", "extract_component_cc_info")

FILTER_TEMPLATE_WINDOWS = Label(":private/templates/filter_windows.ps1.tpl")
FILTER_TEMPLATE_LINUX = Label(":private/templates/filter_linux.sh.tpl")

# def cfg5_generate_vtt_workspace_impl(ctx):
#     tools = generate_tools_vtt(ctx)
#     return cfg5_generate_workspace_cc_impl(ctx, ["--genType=VTT", "--buildVTTProject"], tools)

# cfg5_generate_vtt_workspace_def = rule(
#     implementation = cfg5_generate_vtt_workspace_impl,
#     attrs = cfg5_generate_workspace_cc_attrs,
#     doc = """
# Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
# This rule is wrapped with private_is_windows attribute to separate between OS differences.
# Used specifically for the vtt use case, as this adds the correct vtt flags to the Cfg5 call automatically.
# """,
#     toolchains = ["@rules_cfg5//:toolchain_type", "@rules_vtt//:toolchain_type"],
# )

# def cfg5_generate_vtt(name, **kwargs):
#     """Wraps the cfg5_generate_vtt_workspace with the private_is_windows select statement in place

#     Args:
#         name: The unique name of this target
#         **kwargs: All of the attrs of the cfg5_generate_vtt_workspace rule

#     Returns:
#         A cfg5_generate_vtt_workspace_def rule that contains the actual implementation
#     """
#     cfg5_generate_vtt_workspace_def(
#         name = name,
#         private_is_windows = select({
#             "@bazel_tools//src/conditions:host_windows": True,
#             "//conditions:default": False,
#         }),
#         private_filter_template = select({
#             "@bazel_tools//src/conditions:host_windows": FILTER_TEMPLATE_WINDOWS,
#             "//conditions:default": FILTER_TEMPLATE_LINUX,
#         }),
#         **kwargs
#     )

def _cfg5_generate_rt_workspace_cc_impl(ctx):
    return cfg5_generate_workspace_cc_impl(ctx, ["--genType=REAL"])

cfg5_generate_rt_workspace_cc_def = rule(
    implementation = _cfg5_generate_rt_workspace_cc_impl,
    attrs = cfg5_generate_workspace_cc_attrs,
    doc = """
Creates a separate cfg5 workspace containing all the given config files and run the cfg5 in this created directory inside the bazel-bin.
This rule is wrapped with private_is_windows attribute to separate between OS differences.
Used specifically for the rt use case, as this adds the correct rt flags to the Cfg5 call automatically.
""",
    toolchains = ["@rules_cfg5//:toolchain_type"],
)

def cfg5_generate_rt(name, components = [], **kwargs):
    """Wraps the cfg5_generate_rt_workspace with the private_is_windows select statement in place

    Args:
        name: The unique name of this target
        components: List of component names to create separate targets for
        **kwargs: All of the attrs of the cfg5_generate_rt_workspace rule

    Returns:
        A cfg5_generate_rt_workspace_def rule that contains the actual implementation
    """
    cfg5_generate_rt_workspace_cc_def(
        name = name,
        components = components,
        private_is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        private_filter_template = select({
            "@bazel_tools//src/conditions:host_windows": FILTER_TEMPLATE_WINDOWS,
            "//conditions:default": FILTER_TEMPLATE_LINUX,
        }),
        **kwargs
    )

    # Filter and sort actual components (excluding "main")
    actual_components = sorted([comp for comp in components if comp != "main"])

    # Create individual targets for each actual component
    for component in actual_components:
        extract_component_cc_info(
            name = name + "_" + component,
            src = ":" + name,
            component = component,
        )

    # Always create a generic target for unmapped sources and headers
    if actual_components:  # Only create unmapped target if we have components
        extract_component_cc_info(
            name = name + "_unmapped",
            src = ":" + name,
            component = "main",  # "main" contains all unmapped files
        )
