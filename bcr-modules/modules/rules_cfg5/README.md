# rules_cfg5

## Overview

**Module Name:** `rules_cfg5`  
**Current Version:** 0.0.3  
**Purpose:** Bazel rules for DaVinci Configurator 5 (CFG5) code generation and toolchain management

### Description

The `rules_cfg5` module provides Bazel integration for Vector's DaVinci Configurator 5 (CFG5) tool. It enables automated code generation for AUTOSAR projects, including Real-Time (RT) and Virtual Target Time (VTT) configurations. The module creates isolated workspaces for CFG5 execution and provides toolchain definitions for hermetic builds.

### Key Functionality

- **Code Generation**: Generate RT and VTT code from CFG5 projects (.dpa files)
- **Toolchain Management**: Define and use CFG5 toolchains in Bazel builds
- **Component Support**: Generate code for specific components with separate output directories
- **Cross-Platform**: Windows and Linux support with platform-specific execution strategies
- **CcInfo Integration**: Generated code exposed as standard Bazel C/C++ dependencies

---

## Module Structure

```
rules_cfg5/
 BUILD.bazel
 README.md                       # User documentation (this file)
 0.0.2/                          # Version 0.0.2
   └── BUILD.bazel
 0.0.3/                          # Version 0.0.3 (current)
   └── BUILD.bazel
 srcs/                           # Source files
    ├── BUILD.bazel
    ├── MODULE.bazel
    ├── defs.bzl                    # Public API
    ├── generate.bzl                # Generation entry point
    └── private/
        ├── generate.bzl            # Core generation logic
        ├── rules.bzl               # Rule definitions
        ├── start.bzl               # CFG5 startup rules
        ├── toolchains.bzl          # Toolchain definitions
        ├── common/
        │   └── component_refs.bzl  # Component reference utilities
        └── templates/
            ├── filter_linux.sh.tpl     # Linux file filtering
            └── filter_windows.ps1.tpl  # Windows file filtering
```

---

## Installation

Add to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_cfg5", version = "0.0.3")
bazel_dep(name = "rules_common", version = "0.2.0")  # Required dependency
```

---

## Rules and Functions

### cfg5_generate_rt

Generates Real-Time (RT) code from DaVinci Configurator 5 projects.

**Signature:**
```python
cfg5_generate_rt(
    name,
    dpa_file,
    config_files,
    components = [],
    genArgs = [],
    excluded_files = [],
    additional_source_file_endings = [],
    additional_output_files = [],
    config_folders = ["Config"]
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | String | Unique name for this target | Yes | - |
| `dpa_file` | Label | DaVinci project file (.dpa) | Yes | - |
| `config_files` | List[Label] | Configuration files (.arxml, .dpa, etc.) | Yes | - |
| `components` | List[String] | Component names for separate targets | No | `[]` |
| `genArgs` | List[String] | Additional arguments for CFG5 CLI | No | `[]` |
| `excluded_files` | List[String] | File patterns to exclude from generation | No | `[]` |
| `additional_source_file_endings` | List[String] | Additional file endings to include as sources | No | `[]` |
| `additional_output_files` | List[String] | Additional files to extract from generator output | No | `[]` |
| `config_folders` | List[String] | Config folder names for workspace structure | No | `["Config"]` |

**Usage Example:**
```python
load("@rules_cfg5//:defs.bzl", "cfg5_generate_rt")

cfg5_generate_rt(
    name = "my_ecu_config",
    dpa_file = "project/MyEcu.dpa",
    config_files = glob([
        "Config/**/*.arxml",
    ]),
    components = ["BswM", "CanIf", "Com"],
    genArgs = ["--verbose"],
    excluded_files = [
        "*.tmp",
        "*_Test.c",
    ],
)

# Use in cc_library
cc_library(
    name = "ecu_bsw",
    deps = [":my_ecu_config"],
)

# Use component-specific target
cc_library(
    name = "can_stack",
    deps = [":my_ecu_config_CanIf"],
)
```

---

### cfg5_toolchain

Defines a CFG5 toolchain for use in Bazel builds.

**Signature:**
```python
cfg5_toolchain(
    name,
    cfg5cli_path,
    cfg5_path = None,
    cfg5_files = None
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `cfg5cli_path` | Label | Path to the CFG5 CLI executable | Yes | - |
| `cfg5_path` | Label | Path to the CFG5 executable (optional) | No | `None` |
| `cfg5_files` | Label | Optional CFG5 files for hermetic execution | No | `None` |

**Usage Example:**
```python
load("@rules_cfg5//:defs.bzl", "cfg5_toolchain")

cfg5_toolchain(
    name = "cfg5_linux_toolchain",
    cfg5cli_path = "@davinci_cfg5//:bin/DVCfg5Cli",
)

toolchain(
    name = "cfg5_toolchain",
    exec_compatible_with = ["@platforms//os:linux"],
    target_compatible_with = ["@platforms//os:linux"],
    toolchain = ":cfg5_linux_toolchain",
    toolchain_type = "@rules_cfg5//:toolchain_type",
)
```

---

### start_cfg5_windows

Starts CFG5 GUI on Windows with specified project and arguments.

**Signature:**
```python
start_cfg5_windows(
    name,
    dpa,
    cfg5_args = "",
    config_files = [],
    script = None
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `dpa` | Label | The .dpa project file to start CFG5 with | Yes | - |
| `cfg5_args` | String | Additional CFG5 command-line arguments | No | `""` |
| `config_files` | List[Label] | Additional configuration files | No | `[]` |
| `script` | Label | Script task/location to add to CFG5 | No | `None` |

**Usage Example:**
```python
load("@rules_cfg5//:defs.bzl", "start_cfg5_windows")

start_cfg5_windows(
    name = "open_my_project",
    dpa = "project/MyEcu.dpa",
    config_files = glob(["Config/**/*.arxml"]),
    cfg5_args = "--verbose",
)
```

---

## Usage Guide

### Setup CFG5 Toolchain

1. **Add module dependency in MODULE.bazel:**
```python
bazel_dep(name = "rules_cfg5", version = "0.0.3")
bazel_dep(name = "rules_common", version = "0.2.0")
```

2. **Define CFG5 toolchain in BUILD.bazel:**
```python
load("@rules_cfg5//:defs.bzl", "cfg5_toolchain")

cfg5_toolchain(
    name = "my_cfg5_toolchain",
    cfg5cli_path = "@davinci_tools//:DVCfg5Cli",
)

toolchain(
    name = "cfg5_toolchain",
    exec_compatible_with = ["@platforms//os:linux"],
    target_compatible_with = ["@platforms//os:linux"],
    toolchain = ":my_cfg5_toolchain",
    toolchain_type = "@rules_cfg5//:toolchain_type",
)
```

3. **Register toolchain in MODULE.bazel:**
```python
register_toolchains("//path/to:cfg5_toolchain")
```

### Generate Code from CFG5 Project

```python
load("@rules_cfg5//:defs.bzl", "cfg5_generate_rt")

cfg5_generate_rt(
    name = "ecu_bsw_gen",
    dpa_file = "project/EcuBsw.dpa",
    config_files = glob([
        "Config/**/*.arxml",
        "Config/**/*.xml",
    ]),
    components = ["BswM", "CanIf", "CanTp", "Com", "PduR"],
    genArgs = [
        "--verbose",
        "--logLevel=INFO",
    ],
    excluded_files = [
        "*_Test.c",
        "*_unittest.c",
    ],
)

# Use generated code in C library
cc_library(
    name = "bsw",
    deps = [":ecu_bsw_gen"],
    includes = ["."],
)

# Use component-specific target
cc_library(
    name = "can_stack",
    deps = [
        ":ecu_bsw_gen_CanIf",
        ":ecu_bsw_gen_CanTp",
    ],
)
```

---

## Dependencies

### Required Bazel Modules
- `rules_common` (version 0.2.0 or higher) - Provides workspace creation utilities
- `bazel_skylib` (version 1.7.1 or higher) - Common Bazel utilities
- `rules_cc` - C/C++ rules for CcInfo providers

### External Tools
- **DaVinci Configurator 5**: CFG5 CLI executable must be available
  - Linux: Executable with proper permissions
  - Windows: .exe executable

---

## Platform Support

| Platform | Support Level | Notes |
|----------|--------------|-------|
| Linux (x64) | ✅ Full | Requires executable permissions on CFG5 CLI |
| Windows (x64) | ✅ Full | Uses PowerShell for execution |
| macOS | ❌ Not Supported | DaVinci tools not available |

---

## Configuration Requirements

### DPA File Configuration

The output directory for GenData in the .dpa file must be set to:

```xml
<GenData>../GenData</GenData>
<GenDataVtt>../GenDataVtt</GenDataVtt>
```

---

## Limitations

1. **Single Generation Type**: One rule instance supports either RT or VTT generation, not both simultaneously
2. **Workspace Location**: Generated workspaces created in `bazel-bin` directory
3. **File Filtering**: Uses template-based filtering (platform-specific)
4. **Readonly Handling**: DPA files copied to workaround Bazel readonly restrictions
5. **Component Names**: Must match exactly with CFG5 project component names
6. **Path Restrictions**: Deep nested paths in config files may cause issues with workspace creation
7. **VTT Support**: VTT generation currently commented out (not part of FOSS release)

---

## Advanced Features

### Component-Specific Code Generation

When `components` list is provided, the rule creates separate targets for each component:
- Main target: `{name}` - All generated code
- Component targets: `{name}_{ComponentName}` - Component-specific code

Example:
```python
cfg5_generate_rt(
    name = "bsw",
    components = ["CanIf", "Com"],
    # ... other attributes
)

# Creates targets:
# - :bsw (all code)
# - :bsw_CanIf (CanIf only)
# - :bsw_Com (Com only)
```

### File Filtering

Control which files are included/excluded from generation:

```python
cfg5_generate_rt(
    name = "config",
    excluded_files = [
        "*_Test.c",           # Exclude test files
        "*_PreCompile.c",     # Exclude precompile config
        "vLinkGen_Lcfg.c",    # Excluded by default for VTT
    ],
    additional_source_file_endings = [
        "*.asm",              # Include assembly files
        "*.s",                # Include additional source types
    ],
    # ...
)
```

### Custom CFG5 Arguments

Pass additional arguments directly to CFG5 CLI:

```python
cfg5_generate_rt(
    name = "config",
    genArgs = [
        "--verbose",
        "--logLevel=DEBUG",
        "--reportArgs=CreateXmlFile",
        "--genType=REAL",
    ],
    # ...
)
```

---

## Troubleshooting

### Issue: "CFG5 toolchain not found"

**Solution:** Ensure CFG5 toolchain is properly registered and defined.

```python
# Check MODULE.bazel
bazel_dep(name = "rules_cfg5", version = "0.0.3")

# Check toolchain registration
register_toolchains("//toolchains:cfg5_toolchain")
```

---

### Issue: Generated code not found by compiler

**Solution:** Verify that `CcInfo` is properly consumed and includes are correct.

```python
cc_library(
    name = "my_lib",
    deps = [":cfg5_gen"],  # Ensure dependency is correct
    includes = ["."],      # Add includes if needed
)
```

---

### Issue: Permission denied on Linux

**Solution:** Ensure CFG5 CLI has execute permissions.

```bash
chmod +x path/to/DVCfg5Cli
```

---

### Issue: Component-specific target not created

**Solution:** Verify component name exactly matches CFG5 project component name.

```python
cfg5_generate_rt(
    name = "gen",
    components = ["CanIf"],  # Must match exactly (case-sensitive)
    # ...
)
```

---

### Issue: Deep path errors during workspace creation

**Solution:** Simplify config file structure or adjust `config_folders` attribute.

```python
cfg5_generate_rt(
    name = "gen",
    config_folders = ["Config", "Cfg"],  # Adjust folder matching
    # ...
)
```

---

### Issue: "GenData directory not found"

**Solution:** Verify DPA file has correct GenData path configuration (see Configuration Requirements section above).

---

## Version History

- **0.0.3** (Current): Enhanced component support and filtering
- **0.0.2**: Initial release with RT generation

---

## License

Proprietary - Internal use only
