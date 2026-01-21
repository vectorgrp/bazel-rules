# rules_davinci_developer

## Overview

**Module Name:** `rules_davinci_developer`  
**Current Version:** 0.0.1  
**Purpose:** Bazel toolchain definitions for Vector's DaVinci Developer tool suite

### Description

The `rules_davinci_developer` module provides Bazel toolchain integration for Vector's DaVinci Developer tools, including DVImEx (Import/Export) and DVSwcGen (SWC Generator). This module enables automated execution of DaVinci Developer operations within Bazel builds, supporting both command-line operations and GUI launching.

### Key Functionality

- **Toolchain Management**: Define and register DaVinci Developer toolchains for Bazel builds
- **Multi-Binary Support**: Supports multiple DaVinci Developer binaries (DVImEx, DVSwcGen)
- **Command-Line Execution**: Run DaVinci Developer operations in automated builds
- **GUI Launching**: Start DaVinci Developer GUI with specific projects (Windows)
- **Cross-Platform**: Windows (path-based) and Linux (label-based) support
- **Integration**: Used by other rule modules (rules_dvteam, rules_ocs, rules_cfg5)

---

## Module Structure

```
rules_davinci_developer/
├── BUILD.bazel
├── README.md
├── 0.0.1/                          # Version 0.0.1 (current)
│   └── BUILD.bazel
└── srcs/                           # Source files
    ├── BUILD.bazel
    ├── MODULE.bazel
    ├── rules.bzl                   # Rule definitions and implementations
    └── toolchains.bzl              # Toolchain definitions
```

---

## Rules and Toolchains

### davinci_developer_toolchain

Defines a DaVinci Developer toolchain that provides access to DaVinci Developer binaries.

**Location:** `toolchains.bzl`

**Signature:**
```python
davinci_developer_toolchain(
    name,
    dvimex_label = None,
    dvswcgen_label = None,
    dvimex_path = "",
    dvswcgen_path = "",
    davincidev_path = "",
    davinci_developer_cmd_label = None
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `dvimex_label` | Label | Label pointing to DVImEx binary (Linux) | No | `None` |
| `dvswcgen_label` | Label | Label pointing to DVSwcGen binary (Linux) | No | `None` |
| `dvimex_path` | String | System path to DVImEx binary (Windows) | No | `""` |
| `dvswcgen_path` | String | System path to DVSwcGen binary (Windows) | No | `""` |
| `davincidev_path` | String | Path to DaVinciDEV.exe for GUI launch (Windows) | No | `""` |
| `davinci_developer_cmd_label` | Label | Legacy: Developer CMD label (Linux) | No | `None` |

**Usage Example - Linux:**
```python
load("@rules_davinci_developer//:toolchains.bzl", "davinci_developer_toolchain")

davinci_developer_toolchain(
    name = "davinci_dev_linux_toolchain",
    dvimex_label = "@davinci_tools//:DEVImEx/bin/DVImEx",
    dvswcgen_label = "@davinci_tools//:DEVSwcGen/bin/DVSwcGen",
    davinci_developer_cmd_label = "@davinci_tools//:DEVImEx/bin/DVImEx",
)

toolchain(
    name = "davinci_developer_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
    ],
    toolchain = ":davinci_dev_linux_toolchain",
    toolchain_type = "@rules_davinci_developer//:toolchain_type",
)
```

**Usage Example - Windows:**
```python
load("@rules_davinci_developer//:toolchains.bzl", "davinci_developer_toolchain")

davinci_developer_toolchain(
    name = "davinci_dev_windows_toolchain",
    dvimex_path = "C:/Program Files/Vector/DaVinci Developer/DEVImEx/bin/DVImEx.exe",
    dvswcgen_path = "C:/Program Files/Vector/DaVinci Developer/DEVSwcGen/bin/DVSwcGen.exe",
    davincidev_path = "C:/Program Files/Vector/DaVinci Developer/DaVinciDEV.exe",
)

toolchain(
    name = "davinci_developer_toolchain",
    exec_compatible_with = [
        "@platforms//os:windows",
    ],
    target_compatible_with = [
        "@platforms//os:windows",
    ],
    toolchain = ":davinci_dev_windows_toolchain",
    toolchain_type = "@rules_davinci_developer//:toolchain_type",
)
```

---

### developer_run

Executes DaVinci Developer command-line operations (DVImEx or DVSwcGen).

**Location:** `rules.bzl`

**Signature:**
```python
developer_run(
    name,
    dcf_file,
    binary_name,
    genargs = [],
    inputs = [],
    export_output = None
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `dcf_file` | Label | The .dcf configuration file | Yes | - |
| `binary_name` | String | Which binary to use: "dvimex" or "dvswcgen" | Yes | - |
| `genargs` | List[String] | Additional CLI arguments | No | `[]` |
| `inputs` | List[Label] | Other input files (e.g., model files) | No | `[]` |
| `export_output` | Output | ARXML output file (passed via -ef) | No | `None` |

**Usage Example:**
```python
load("@rules_davinci_developer//:rules.bzl", "developer_run")

developer_run(
    name = "export_swc_description",
    dcf_file = "config/export.dcf",
    binary_name = "dvimex",
    inputs = [
        "models/Application.arxml",
        "models/Platform.arxml",
    ],
    export_output = "generated/SwcDescription.arxml",
    genargs = [
        "-x",
        "--verbose",
    ],
)

# Use exported ARXML in another target
filegroup(
    name = "swc_configs",
    srcs = [":export_swc_description"],
)
```

---

### start_developer_windows

Launches DaVinci Developer GUI with a specific project (Windows only).

**Location:** `rules.bzl`

**Signature:**
```python
start_developer_windows(
    name,
    dcf,
    model,
    developer_args = ""
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `dcf` | Label | The .dcf file to open | Yes | - |
| `model` | Label | The .arxml model referenced by the DCF | Yes | - |
| `developer_args` | String | Additional DaVinci Developer arguments | No | `""` |

**Usage Example:**
```python
load("@rules_davinci_developer//:rules.bzl", "start_developer_windows")

start_developer_windows(
    name = "open_my_project",
    dcf = "project/MyApp.dcf",
    model = "models/Application.arxml",
    developer_args = "--verbose",
)
```

**Running:**
```bash
bazel run //:open_my_project
```

---

## Usage Guide

### Setup DaVinci Developer Toolchain

1. **Add module dependency in MODULE.bazel:**
```python
bazel_dep(name = "rules_davinci_developer", version = "0.0.1")
```

2. **Define toolchain in BUILD.bazel (Linux):**
```python
load("@rules_davinci_developer//:toolchains.bzl", "davinci_developer_toolchain")

# Download DaVinci Developer tools
http_archive(
    name = "davinci_tools",
    url = "https://example.com/davinci_developer_linux.tar.gz",
    sha256 = "...",
    build_file_content = """
filegroup(
    name = "DEVImEx",
    srcs = ["DEVImEx/bin/DVImEx"],
    visibility = ["//visibility:public"],
)
filegroup(
    name = "DEVSwcGen",
    srcs = ["DEVSwcGen/bin/DVSwcGen"],
    visibility = ["//visibility:public"],
)
""",
)

davinci_developer_toolchain(
    name = "davinci_dev_toolchain_impl",
    dvimex_label = "@davinci_tools//:DEVImEx",
    dvswcgen_label = "@davinci_tools//:DEVSwcGen",
    davinci_developer_cmd_label = "@davinci_tools//:DEVImEx",
)

toolchain(
    name = "davinci_developer_toolchain",
    exec_compatible_with = ["@platforms//os:linux"],
    toolchain = ":davinci_dev_toolchain_impl",
    toolchain_type = "@rules_davinci_developer//:toolchain_type",
)
```

3. **Register toolchain in MODULE.bazel:**
```python
register_toolchains("//path/to:davinci_developer_toolchain")
```

### Export ARXML with DVImEx

```python
load("@rules_davinci_developer//:rules.bzl", "developer_run")

developer_run(
    name = "export_component_description",
    dcf_file = "export_config/ComponentExport.dcf",
    binary_name = "dvimex",
    inputs = [
        "models/ComponentDefinition.arxml",
    ],
    export_output = "generated/ComponentDescription.arxml",
    genargs = ["-x"],  # Export mode
)
```

### Generate SWC with DVSwcGen

```python
developer_run(
    name = "generate_swc_code",
    dcf_file = "swc_config/SwcGen.dcf",
    binary_name = "dvswcgen",
    inputs = [
        "models/SwcDescription.arxml",
    ],
    genargs = [
        "--target=C",
        "--verbose",
    ],
)
```

---

## Dependencies

### Required Bazel Modules
- None (standalone module)

### External Tools
- **DaVinci Developer**: One or more of the following binaries:
  - DVImEx: Import/Export operations
  - DVSwcGen: Software Component generation
  - DaVinciDEV.exe: GUI application (Windows)

---

## Platform Support

| Platform | Support Level | Notes |
|----------|--------------|-------|
| Linux (x64) | ✅ Full | Uses label-based toolchain (requires downloaded binaries) |
| Windows (x64) | ✅ Full | Uses path-based toolchain (system installation) |
| macOS | ❌ Not Supported | DaVinci tools not available |

**Platform Differences:**
- **Linux**: Requires binaries as Bazel labels (downloaded via http_archive or similar)
- **Windows**: Uses system paths to installed DaVinci Developer
- GUI launch (`start_developer_windows`) only supported on Windows

---

## Limitations

1. **Binary Availability**: Requires DaVinci Developer installation or downloaded binaries
2. **Linux Permissions**: Binaries must have execute permissions
3. **Windows Paths**: Windows toolchain requires absolute paths to installed tools
4. **GUI Launch**: Only Windows supports GUI launch rule
5. **Single Binary Per Call**: Each `developer_run` invocation uses one binary (dvimex or dvswcgen)
6. **File Permissions**: May need to handle readonly file attributes (especially on Windows)

---

## Advanced Features

### Multiple Binary Support

The toolchain supports multiple DaVinci Developer binaries:

```python
# Use DVImEx for import/export
developer_run(
    name = "export_arxml",
    binary_name = "dvimex",
    dcf_file = "export.dcf",
    export_output = "output.arxml",
)

# Use DVSwcGen for code generation
developer_run(
    name = "generate_code",
    binary_name = "dvswcgen",
    dcf_file = "codegen.dcf",
)
```

### Custom Arguments

Pass additional arguments to DaVinci Developer:

```python
developer_run(
    name = "export_with_options",
    dcf_file = "config.dcf",
    binary_name = "dvimex",
    genargs = [
        "-x",              # Export mode
        "--verbose",       # Verbose logging
        "--force",         # Force overwrite
    ],
)
```

### Integration with Other Rules

This module is used by other Vector rule modules:

```python
# Used by rules_dvteam
bazel_dep(name = "rules_dvteam")

# Used by rules_ocs
bazel_dep(name = "rules_ocs")

# DVTeam and OCS rules automatically use this toolchain
```

---

## Troubleshooting

### Common Issues

**Issue**: "Developer toolchain is needed for DaVinci Team and needs either..."
- **Solution**: Ensure toolchain is properly defined and registered
- **Check**: At least one of `dvimex_label`/`dvimex_path` or `davinci_developer_cmd_label` must be set

**Issue**: Permission denied on Linux
- **Solution**: Make binaries executable: `chmod +x DVImEx DVSwcGen`
- **Alternative**: Use http_archive with executable permissions

**Issue**: "Invalid binary_name" error
- **Solution**: Use only "dvimex" or "dvswcgen" as binary_name
- **Check**: Spelling and case sensitivity

**Issue**: Windows path not found
- **Solution**: Use absolute paths in Windows toolchain
- **Example**: `C:/Program Files/Vector/DaVinci Developer/DEVImEx/bin/DVImEx.exe`

**Issue**: Export output not created
- **Solution**: Check .dcf file configuration and input files
- **Debug**: Add `--verbose` to genargs and check log file
