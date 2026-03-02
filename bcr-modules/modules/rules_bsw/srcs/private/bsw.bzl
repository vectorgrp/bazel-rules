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

"""Rule to generate BUILD files for BSW packages"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "read_netrc", "read_user_netrc", "use_netrc")

DEFAULT_CANONICAL_ID_ENV = "BAZEL_HTTP_RULES_URLS_AS_DEFAULT_CANONICAL_ID"

_bsw_attrs = {
    "url": attr.string(
        doc = "URL of the BSW package to download. Mutually exclusive with 'path'.",
    ),
    "path": attr.string(
        doc = "Local file system path to BSW package (directory or archive). Mutually exclusive with 'url'.",
    ),
    "strip_prefix": attr.string(
        doc = "Optional strip_prefix value for the downloaded/extracted archive",
    ),
    "integrity": attr.string(
        doc = "Integrity string for the package (only used with 'url')",
    ),
    "netrc": attr.string(
        doc = "Location of the .netrc file to use for authentication (only used with 'url')",
    ),
    "auth_patterns": attr.string_dict(
        doc = "Authentication patterns for URL matching (only used with 'url')",
    ),
    "cfg5_linux_url": attr.string(
        doc = "Optional URL for Linux cfg5 tool. If specified and running on Linux, downloads and replaces the DaVinciConfigurator folder.",
    ),
    "cfg5_linux_integrity": attr.string(
        doc = "Integrity string for the Linux cfg5 tool (only used with 'cfg5_linux_url')",
    ),
    "cfg5_linux_strip_prefix": attr.string(
        doc = "Optional strip_prefix for the Linux cfg5 tool archive",
    ),
}

def _get_auth(repository_ctx, urls):
    """Retrieve authentication credentials from netrc files."""
    if repository_ctx.attr.netrc:
        netrc = read_netrc(repository_ctx, repository_ctx.attr.netrc)
    elif "NETRC" in repository_ctx.os.environ:
        netrc = read_netrc(repository_ctx, repository_ctx.os.environ["NETRC"])
    else:
        netrc = read_user_netrc(repository_ctx)
    return use_netrc(netrc, urls, repository_ctx.attr.auth_patterns)

def _update_attrs(orig, keys, override):
    """Update attributes for reproducibility tracking.

    Args:
        orig: Original attributes from the rule invocation
        keys: Complete set of defined attributes
        override: Attributes to override or add

    Returns:
        Updated attribute dictionary
    """
    result = {}
    for key in keys:
        if getattr(orig, key) != None:
            result[key] = getattr(orig, key)
    result["name"] = orig.name
    result.update(override)
    return result

def _is_valid_file(filename):
    """Check if a file is valid for processing. Excludes files starting with '_'."""
    return not filename.startswith("_")

def _discover_component_files(repository_ctx, component_path):
    """Discover headers, sources, and unity sources in a component's Implementation directory.

    Returns:
        Dictionary with keys: headers, sources, unity_sources (all as sorted lists)
    """
    impl_path = repository_ctx.path(component_path + "/Implementation")
    if not impl_path.exists:
        return None

    headers = []
    sources = []
    unity_sources = []

    for entry in impl_path.readdir():
        filename = entry.basename
        if not _is_valid_file(filename):
            continue

        file_path = "Implementation/" + filename
        if filename.endswith(".h"):
            headers.append(file_path)
        elif filename.endswith((".c", ".asm", ".s", ".S")):
            if filename.endswith("_Unity.c"):
                unity_sources.append(file_path)
            else:
                sources.append(file_path)

    return {
        "headers": sorted(headers),
        "sources": sorted(sources),
        "unity_sources": sorted(unity_sources),
    }

def _create_vttcanoeemu_build_file(repository_ctx, comp_dir, headers):
    """Create BUILD.bazel file for VttCANoeEmu component with exported .lib files."""

    # Find all .lib files in the Implementation directory
    impl_dir = repository_ctx.path(comp_dir + "/Implementation")
    lib_files = []
    if impl_dir.exists:
        for entry in impl_dir.readdir():
            if entry.basename.endswith(".lib"):
                lib_files.append("Implementation/" + entry.basename)

    build_content = 'load("@rules_cc//cc:defs.bzl", "cc_library")\n\n'
    build_content += 'package(default_visibility = ["//visibility:public"])\n\n'

    # Export all .lib files
    if lib_files:
        build_content += "exports_files([\n"
        for lib in sorted(lib_files):
            build_content += '    "' + lib + '",\n'
        build_content += "])\n\n"

    # Create cc_library for headers (without .lib files)
    build_content += "cc_library(\n"
    build_content += '    name = "VttCANoeEmu_headers",\n'
    build_content += "    hdrs = [\n"
    for h in headers:
        build_content += '        "' + h + '",\n'
    build_content += "    ],\n"
    build_content += '    includes = ["Implementation"],\n'
    build_content += ")\n"

    repository_ctx.file(comp_dir + "/BUILD.bazel", build_content)

def _create_vttcntrl_build_file(repository_ctx, comp_dir, headers, sources):
    """Create BUILD.bazel file for VttCntrl component with individual filegroups per source."""

    # Default sources that go into VttCntrl_sources
    default_sources = []

    # Individual sources that get their own filegroups
    individual_sources = {}

    for src in sources:
        filename = src.split("/")[-1]  # Get basename

        # VttCntrl.c and VttCntrl_SysVar.c go into default sources
        if filename in ["VttCntrl.c", "VttCntrl_SysVar.c"]:
            default_sources.append(src)
            # Other VttCntrl_*.c files get individual filegroups

        elif filename.startswith("VttCntrl_") and filename.endswith(".c"):
            # Extract the module name (e.g., "Can" from "VttCntrl_Can.c")
            module_name = filename[9:-2]  # Remove "VttCntrl_" prefix and ".c" suffix
            individual_sources[module_name] = src

    build_content = 'load("@rules_cc//cc:defs.bzl", "cc_library")\n\n'
    build_content += 'package(default_visibility = ["//visibility:public"])\n\n'

    # Create cc_library for headers
    build_content += "cc_library(\n"
    build_content += '    name = "VttCntrl_headers",\n'
    build_content += "    hdrs = [\n"
    for h in headers:
        build_content += '        "' + h + '",\n'
    build_content += "    ],\n"
    build_content += '    includes = ["Implementation"],\n'
    build_content += ")\n\n"

    # Create default sources filegroup
    build_content += "filegroup(\n"
    build_content += '    name = "VttCntrl_sources",\n'
    build_content += "    srcs = [\n"
    for s in default_sources:
        build_content += '        "' + s + '",\n'
    build_content += "    ],\n"
    build_content += ")\n\n"

    # Create individual filegroups for each module
    for module_name in sorted(individual_sources.keys()):
        build_content += "filegroup(\n"
        build_content += '    name = "VttCntrl_' + module_name + '_sources",\n'
        build_content += "    srcs = [\n"
        build_content += '        "' + individual_sources[module_name] + '",\n'
        build_content += "    ],\n"
        build_content += ")\n\n"

    repository_ctx.file(comp_dir + "/BUILD.bazel", build_content)

def _create_component_build_file(repository_ctx, comp_dir, comp_name, file_info):
    """Create standard BUILD.bazel file for a component.

    If Unity build exists: headers filegroup contains .h + .c files, sources contains Unity files
    Otherwise: headers contains only .h files, sources contains .c files
    """
    headers = file_info["headers"]
    sources = file_info["sources"]
    unity_sources = file_info["unity_sources"]

    if unity_sources:
        filegroup_headers = headers + sources
        filegroup_sources = unity_sources
    else:
        filegroup_headers = headers
        filegroup_sources = sources

    build_content = 'load("@rules_cc//cc:defs.bzl", "cc_library")\n\n'
    build_content += 'package(default_visibility = ["//visibility:public"])\n\n'

    # Headers cc_library
    build_content += "cc_library(\n"
    build_content += '    name = "' + comp_name + '_headers",\n'
    build_content += "    hdrs = [\n"
    for h in filegroup_headers:
        build_content += '        "' + h + '",\n'
    build_content += "    ],\n"
    build_content += '    includes = ["Implementation"],\n'
    build_content += ")\n\n"

    # Sources filegroup
    build_content += "filegroup(\n"
    build_content += '    name = "' + comp_name + '_sources",\n'
    build_content += "    srcs = [\n"
    for s in filegroup_sources:
        build_content += '        "' + s + '",\n'
    build_content += "    ],\n"
    build_content += ")\n"

    repository_ctx.file(comp_dir + "/BUILD.bazel", build_content)

def _bazelise_bsw_components(repository_ctx):
    """Discover and bazelise all BSW components."""
    components_dir = repository_ctx.path("Components")

    if not components_dir.exists:
        fail("Components directory does not exist: {}".format(components_dir))

    all_components = {}

    # Discover all components
    for component in components_dir.readdir():
        if not component.basename.startswith("."):
            component_name = component.basename
            component_path = "Components/" + component_name
            file_info = _discover_component_files(repository_ctx, component_path)

            if file_info:
                all_components[component_name] = file_info

                # Create BUILD.bazel for this component
                comp_dir = component_path

                # Special handling for VttCANoeEmu component
                if component_name == "VttCANoeEmu":
                    _create_vttcanoeemu_build_file(repository_ctx, comp_dir, file_info["headers"])
                    # Special handling for VttCntrl component

                elif component_name == "VttCntrl":
                    _create_vttcntrl_build_file(repository_ctx, comp_dir, file_info["headers"], file_info["sources"])
                    # Standard handling for other components

                else:
                    _create_component_build_file(repository_ctx, comp_dir, component_name, file_info)

def _create_root_build_file(repository_ctx):
    """Create the root BUILD.bazel file with conditional DaVinci Configurator exports."""

    # Check if DaVinciConfigurator directory exists
    davinci_path = repository_ctx.path("DaVinciConfigurator")
    has_davinci = davinci_path.exists

    # Start building the BUILD file content
    build_content = 'package(default_visibility = ["//visibility:public"])\n\n'

    if has_davinci:
        # Detect which executables exist (Windows vs Linux) and export them

        # Check for DVCfgCmd executable (command-line tool)
        dvcfgcmd = repository_ctx.path("DaVinciConfigurator/Core/DVCfgCmd")
        dvcfgcmd_exe = repository_ctx.path("DaVinciConfigurator/Core/DVCfgCmd.exe")

        # Check for DaVinciCfg/DaVinciCFG executable (GUI tool, only windows)
        davinci_cfg_lower = repository_ctx.path("DaVinciConfigurator/Core/DaVinciCfg.exe")
        davinci_cfg_upper = repository_ctx.path("DaVinciConfigurator/Core/DaVinciCFG.exe")

        # Export DVCfgCmd
        if dvcfgcmd.exists:
            build_content += 'exports_files(["DaVinciConfigurator/Core/DVCfgCmd"])\n'
        if dvcfgcmd_exe.exists:
            build_content += 'exports_files(["DaVinciConfigurator/Core/DVCfgCmd.exe"])\n'

        # Export DaVinciCfg/DaVinciCFG
        if davinci_cfg_lower.exists:
            build_content += 'exports_files(["DaVinciConfigurator/Core/DaVinciCfg.exe"])\n\n'
        elif davinci_cfg_upper.exists:
            build_content += 'exports_files(["DaVinciConfigurator/Core/DaVinciCFG.exe"])\n\n'
        else:
            # No DaVinciCfg found, just add spacing
            build_content += "\n"

        build_content += "# Export explicitly required files\n"
        build_content += "filegroup(\n"
        build_content += '    name = "DaVinci_Configurator_5",\n'
        build_content += "    srcs = glob(\n"
        build_content += "        [\n"
        build_content += '            "DaVinciConfigurator/**/*",\n'
        build_content += "        ],\n"
        build_content += "        exclude = [\n"
        build_content += '           "DaVinciConfigurator/**/org.eclipse.core.runtime/**",\n'
        build_content += '           "DaVinciConfigurator/**/configuration/**",\n'
        build_content += '           "DaVinciConfigurator/**/.metadata/**",\n'
        build_content += '           "DaVinciConfigurator/**/.instance",\n'
        build_content += '           "DaVinciConfigurator/**/*.lock",\n'
        build_content += '           "DaVinciConfigurator/**/*.manager",\n'
        build_content += "        ],\n"
        build_content += "    ),\n"
        build_content += ")\n\n"

    # Always create package filegroup
    build_content += "filegroup(\n"
    build_content += '    name = "package",\n'
    build_content += "    srcs = glob(\n"
    build_content += "        [\n"
    build_content += '            "**/*",\n'
    build_content += "        ],\n"
    build_content += "        exclude = [\n"
    build_content += '           "**/org.eclipse.core.runtime/**",\n'
    build_content += '           "**/configuration/**",\n'
    build_content += '           "**/.metadata/**",\n'
    build_content += '           "**/.instance",\n'
    build_content += '           "**/*.lock",\n'
    build_content += '           "**/.manager/**",\n'
    build_content += "        ],\n"
    build_content += "    ),\n"
    build_content += ")\n"

    # Write the BUILD.bazel file
    repository_ctx.file("BUILD.bazel", build_content, executable = False)

def _bsw_impl(repository_ctx):
    """Implementation of the bazelise_bsw repository rule."""

    # Validate that exactly one of url or path is provided
    if repository_ctx.attr.url and repository_ctx.attr.path:
        fail("Cannot specify both 'url' and 'path'. Choose one source for the BSW package.")
    if not repository_ctx.attr.url and not repository_ctx.attr.path:
        fail("Must specify either 'url' or 'path' to locate the BSW package.")
    if not repository_ctx.attr.url:
        local_path = repository_ctx.path(repository_ctx.attr.path)
        repository_ctx.watch_tree(local_path)  # Watch local dir for changes

    download_info = None

    if repository_ctx.attr.url:
        # Download from URL
        auth = _get_auth(repository_ctx, [repository_ctx.attr.url])
        download_info = repository_ctx.download_and_extract(
            url = [repository_ctx.attr.url],
            integrity = repository_ctx.attr.integrity,
            stripPrefix = repository_ctx.attr.strip_prefix,
            auth = auth,
        )
    else:
        # Use local path
        local_path = repository_ctx.path(repository_ctx.attr.path)

        if not local_path.exists:
            fail("Local BSW path does not exist: {}".format(repository_ctx.attr.path))

        # Check if it's a directory or an archive
        if str(local_path).endswith((".zip", ".tar.gz", ".tgz", ".tar.bz2", ".tar.xz")):
            # Extract archive
            repository_ctx.extract(
                archive = local_path,
                stripPrefix = repository_ctx.attr.strip_prefix,
            )
        else:
            # Assume it's a directory - symlink the contents
            # If prefix is specified, we need to handle it
            if repository_ctx.attr.strip_prefix:
                source_dir = local_path.get_child(repository_ctx.attr.strip_prefix)
                if not source_dir.exists:
                    fail("Prefix '{}' not found in local path: {}".format(repository_ctx.attr.strip_prefix, repository_ctx.attr.path))

                # Symlink contents from prefixed directory
                for item in source_dir.readdir():
                    repository_ctx.symlink(item, item.basename)
            else:
                # Symlink entire directory contents
                for item in local_path.readdir():
                    repository_ctx.symlink(item, item.basename)

    # Download Linux cfg5 tool if specified and running on Linux
    if repository_ctx.attr.cfg5_linux_url:
        os_name = repository_ctx.os.name.lower()
        if "linux" in os_name:
            # Remove existing DaVinciConfigurator folder completely
            davinci_path = repository_ctx.path("DaVinciConfigurator")
            if davinci_path.exists:
                repository_ctx.execute(["rm", "-rf", "DaVinciConfigurator"])

            # Download and extract Linux cfg5 tool
            auth = _get_auth(repository_ctx, [repository_ctx.attr.cfg5_linux_url])
            repository_ctx.download_and_extract(
                url = [repository_ctx.attr.cfg5_linux_url],
                integrity = repository_ctx.attr.cfg5_linux_integrity,
                stripPrefix = repository_ctx.attr.cfg5_linux_strip_prefix,
                auth = auth,
                output = "DaVinciConfigurator",
            )

    # Bazelise BSW components
    _bazelise_bsw_components(repository_ctx)

    # Create root BUILD.bazel file
    _create_root_build_file(repository_ctx)

    # Return updated attributes with integrity for reproducibility (only for URL downloads)
    if download_info:
        return _update_attrs(repository_ctx.attr, _bsw_attrs.keys(), {"integrity": download_info.integrity})
    else:
        return _update_attrs(repository_ctx.attr, _bsw_attrs.keys(), {})

bsw = repository_rule(
    implementation = _bsw_impl,
    attrs = _bsw_attrs,
    doc = """Bazelise a Vector MICROSAR BSW package.
    
This rule:
1. Downloads a BSW package from URL OR uses a local file system path
2. Extracts archives or symlinks directories (with optional strip_prefix)
3. Auto-discovers all BSW components in Components/ directory
4. Generates BUILD.bazel files for each component with _headers and _sources filegroups
5. Optionally downloads Linux cfg5 tool to replace Windows version on Linux platforms

Example (URL download):
    bsw(
        name = "bsw",
        url = "https://artifactory.example.com/bsw-package.zip",
        integrity = "sha256-abc123...",
        strip_prefix = "BSW-1.0.0",
        auth_patterns = {"artifactory.example.com": "netrc"},
    )

Example (URL download with Linux cfg5 tool):
    bsw(
        name = "bsw",
        url = "https://artifactory.example.com/bsw-package.zip",
        integrity = "sha256-abc123...",
        strip_prefix = "BSW-1.0.0",
        cfg5_linux_url = "https://artifactory.example.com/cfg5-linux.tar.gz",
        cfg5_linux_integrity = "sha256-def456...",
        cfg5_linux_strip_prefix = "DaVinciConfigurator",
        auth_patterns = {"artifactory.example.com": "netrc"},
    )

Example (local path - directory):
    bsw(
        name = "bsw",
        path = "/path/to/bsw/directory",
    )

Example (local path - archive):
    bsw(
        name = "bsw",
        path = "/path/to/bsw-package.zip",
        strip_prefix = "BSW-1.0.0",
    )
""",
    environ = [DEFAULT_CANONICAL_ID_ENV],
)
