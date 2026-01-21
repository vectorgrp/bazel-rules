# rules_ocs

## Overview

**Module Name:** `rules_ocs`  
**Current Version:** 0.0.1  
**Purpose:** Bazel rules for Open Configurator Services (OCS) execution and CFG5 script task automation

### Description

The `rules_ocs` module provides Bazel integration for Vector's Open Configurator Services (OCS) framework and CFG5 script task execution. OCS allows custom plugins and automation workflows to be executed within DaVinci Configurator 5 environment. The module also includes utilities for building OCS application packages (uber JARs).

### Key Functionality

- **OCS Execution**: Run OCS applications/plugins within CFG5 environment
- **Script Task Execution**: Execute CFG5 script tasks (DVGroovy, JAR)
- **Project Management**: Create or modify DaVinci projects via OCS
- **Input File Updates**: Update project input files via OCS configuration
- **OCS App Building**: Build uber JAR packages for OCS applications
- **Cross-Platform**: Windows and Linux support with platform-specific execution

---

## Module Structure

```
rules_ocs/
 BUILD.bazel
 README.md
 0.0.1/                          # Version 0.0.1 (current)
   └── BUILD.bazel
 srcs/                           # Source files
    ├── BUILD.bazel
 MODULE.bazel    ├
    ├── defs.bzl                    # Public API
    └── private/
        ├── app_building.bzl        # OCS app packaging
        ├── rules.bzl               # OCS and script task rules
        └── toolchains.bzl          # 7-Zip toolchain (Windows)
```

---

## Rules and Functions

### ocs

Executes OCS (Open Configurator Services) applications within CFG5 environment.

**Location:** `private/rules.bzl` (exported via `defs.bzl`)

**Signature:**
```python
ocs(
    name,
    ocs_app,
    result,
    dpa_file = None,
    input_files = [],
    davinci_project_files = [],
    ocs_config_files = [],
    ocs_args = ""
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `ocs_app` | Label | The OCS application JAR file | Yes | - |
| `result` | List[Output] | Expected output files from OCS execution | Yes | - |
| `dpa_file` | Label | DaVinci project file (if modifying existing project) | No | `None` |
| `input_files` | List[Label] | Input files (.arxml, .cdd, .dbc) for input file updates | No | `[]` |
| `davinci_project_files` | List[Label] | Project files (.arxml, .dcf, .xml) if modifying project | No | `[]` |
| `ocs_config_files` | List[Label] | OCS plugin JSON configuration files | No | `[]` |
| `ocs_args` | String | Additional arguments for OCS execution | No | `""` |

**Usage Example:**
```python
load("@rules_ocs//:defs.bzl", "ocs")

ocs(
    name = "run_custom_plugin",
    ocs_app = "plugins/MyCustomPlugin.jar",
    ocs_config_files = glob([
        "plugins/CreateProject.json",
        "plugins/InputFilesUpdate.json",
        "plugins/config/*.json",
    ]),
    dpa_file = "project/EcuBsw.dpa",
    davinci_project_files = glob([
        "project/Config/**/*.arxml",
        "project/Config/**/*.xml",
    ]),
    input_files = [
        "input/System.arxml",
        "input/Communication.dbc",
    ],
    result = [
        "output/ModifiedConfig.arxml",
        "output/GeneratedReport.xml",
    ],
    ocs_args = "--verbose --debug",
)
```

---

### cfg5_execute_script_task

Executes a CFG5 script task (DVGroovy or JAR script).

**Location:** `private/rules.bzl` (exported via `defs.bzl`)

**Signature:**
```python
cfg5_execute_script_task(
    name,
    dpa_file,
    script,
    script_task,
    result,
    davinci_project_files = []
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `dpa_file` | Label | DaVinci project file | Yes | - |
| `script` | Label | Script file (.jar or .dvgroovy) | Yes | - |
| `script_task` | String | Name of the script task to execute | Yes | - |
| `result` | List[Output] | Expected output files from script execution | Yes | - |
| `davinci_project_files` | List[Label] | Project files if project is modified | No | `[]` |

**Usage Example:**
```python
load("@rules_ocs//:defs.bzl", "cfg5_execute_script_task")

cfg5_execute_script_task(
    name = "execute_validation_script",
    dpa_file = "project/EcuBsw.dpa",
    script = "scripts/ValidateConfiguration.dvgroovy",
    script_task = "ValidateConfig",
    davinci_project_files = glob([
        "project/Config/**/*.arxml",
    ]),
    result = [
        "output/ValidationReport.xml",
        "output/ValidationLog.txt",
    ],
)

# Example with JAR script
cfg5_execute_script_task(
    name = "generate_documentation",
    dpa_file = "project/EcuBsw.dpa",
    script = "scripts/DocGenerator.jar",
    script_task = "GenerateDocs",
    result = [
        "output/Documentation.pdf",
    ],
)
```

---

### create_ocs_app_deploy_rule

Creates an OCS application deployment package (uber JAR) by combining and repacking JAR dependencies.

**Location:** `private/app_building.bzl` (exported via `defs.bzl`)

**Signature:**
```python
create_ocs_app_deploy_rule(
    name,
    deploy_src,
    jar_file,
    additional_libs = []
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `deploy_src` | Label | Source JAR file to deploy | Yes | - |
| `jar_file` | String | Output JAR file name | Yes | - |
| `additional_libs` | List[Label] | Additional library JARs to include | No | `[]` |

**Usage Example:**
```python
load("@rules_ocs//:defs.bzl", "create_ocs_app_deploy_rule")

create_ocs_app_deploy_rule(
    name = "build_ocs_plugin",
    deploy_src = "//src/main:plugin_deploy.jar",
    jar_file = "MyOcsPlugin.jar",
    additional_libs = [
        "@maven//:com_google_guava_guava",
        "@maven//:org_json_json",
    ],
)
```

---

### seven_zip_toolchain

Defines 7-Zip toolchain for Windows OCS app building.

**Location:** `private/toolchains.bzl` (exported via `defs.bzl`)

**Signature:**
```python
seven_zip_toolchain(
    name,
    sevenzip_dir = ""
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `sevenzip_dir` | String | Path to 7-Zip installation directory | No | `""` |

**Usage Example:**
```python
load("@rules_ocs//:defs.bzl", "seven_zip_toolchain")

seven_zip_toolchain(
    name = "seven_zip_toolchain_impl",
    sevenzip_dir = "C:/Program Files/7-Zip",
)

toolchain(
    name = "seven_zip_toolchain",
    exec_compatible_with = ["@platforms//os:windows"],
    toolchain = ":seven_zip_toolchain_impl",
    toolchain_type = "//rules/ocs:toolchain_type",
)
```

---

## Usage Guide

### Setup OCS Environment

1. **Add module dependencies in MODULE.bazel:**
```python
bazel_dep(name = "rules_ocs", version = "0.0.1")
bazel_dep(name = "rules_davinci_developer", version = "0.0.1")
bazel_dep(name = "rules_cfg5", version = "0.0.3")
bazel_dep(name = "rules_common", version = "0.2.0")

# Required for Linux execution
bazel_dep(name = "rules_dotnet", version = "0.17.5")
dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "8.0.103")
use_repo(dotnet, "dotnet_toolchains")
```

2. **Define required toolchains in BUILD.bazel:**
```python
load("@rules_davinci_developer//:toolchains.bzl", "davinci_developer_toolchain")
load("@rules_cfg5//:defs.bzl", "cfg5_toolchain")

# DaVinci Developer toolchain
davinci_developer_toolchain(
    name = "davinci_dev_toolchain_impl",
    davinci_developer_cmd_label = "@davinci_tools//:DEVImEx",
)

toolchain(
    name = "davinci_developer_toolchain",
    toolchain = ":davinci_dev_toolchain_impl",
    toolchain_type = "@rules_davinci_developer//:toolchain_type",
)

# CFG5 toolchain
cfg5_toolchain(
    name = "cfg5_toolchain_impl",
    cfg5cli_path = "@davinci_cfg5//:DVCfg5Cli",
)

toolchain(
    name = "cfg5_toolchain",
    toolchain = ":cfg5_toolchain_impl",
    toolchain_type = "@rules_cfg5//:toolchain_type",
)
```

3. **Register toolchains in MODULE.bazel:**
```python
register_toolchains(
    "//toolchains:davinci_developer_toolchain",
    "//toolchains:cfg5_toolchain",
)
```

### Execute OCS Application

```python
load("@rules_ocs//:defs.bzl", "ocs")

ocs(
    name = "run_ocs_plugin",
    ocs_app = "plugins/MyPlugin.jar",
    ocs_config_files = glob(["plugins/config/*.json"]),
    dpa_file = "project/MyProject.dpa",
    davinci_project_files = glob(["project/Config/**/*"]),
    result = ["output/result.arxml"],
)
```

### Execute CFG5 Script Task

```python
load("@rules_ocs//:defs.bzl", "cfg5_execute_script_task")

cfg5_execute_script_task(
    name = "run_script",
    dpa_file = "project/MyProject.dpa",
    script = "scripts/MyScript.dvgroovy",
    script_task = "MyTask",
    result = ["output/result.txt"],
)
```

### OCS Configuration Files

OCS supports special configuration JSON files:

**CreateProject.json** - Creates new DaVinci project:
```json
{
  "generalSettings": {
    "projectFolder": "path/to/project"
  },
  "developerWorkspace": {
    "developerExecutable": "path/to/DaVinciDEV.exe"
  }
}
```

**InputFilesUpdate.json** - Updates input files in project:
```json
{
  "inputFiles": [
    {
      "path": "path/to/input.arxml",
      "type": "AUTOSAR"
    }
  ]
}
```

The rule automatically modifies these files with correct paths.

---

## Dependencies

### Required Bazel Modules
- `rules_davinci_developer` - DaVinci Developer toolchain
- `rules_cfg5` - DaVinci Configurator 5 toolchain
- `rules_common` - Common utilities
- `rules_dotnet` (Linux only) - .NET runtime

### External Tools
- **DaVinci Configurator 5**: CFG5 CLI executable
- **DaVinci Developer**: For OCS project operations
- **7-Zip** (Windows only): For OCS app building
- **.NET Runtime** (Linux): For CFG5 execution

---

## Platform Support

| Platform | Support Level | Notes |
|----------|--------------|-------|
| Linux (x64) | ✅ Full | Requires .NET runtime via rules_dotnet |
| Windows (x64) | ✅ Full | Requires 7-Zip for app building |
| macOS | ❌ Not Supported | DaVinci tools not available |

---

## Limitations

1. **Single OCS Task**: Each rule invocation runs one OCS task/script
2. **Output Prediction**: Must pre-declare all expected output files
3. **Project Modification**: Project files copied to handle readonly restrictions
4. **JSON Configuration**: Auto-modification limited to specific JSON formats
5. **7-Zip Dependency**: Windows app building requires 7-Zip
6. **Script Format**: Supports .jar and .dvgroovy scripts only

---

## Advanced Features

### Automatic Path Resolution

The rule automatically resolves paths in OCS configuration files:

- **CreateProject.json**: Updates `projectFolder` and `developerExecutable`
- **InputFilesUpdate.json**: Updates input file paths to Bazel paths

### Project File Management

Automatically handles:
- Copying DPA and config files to workspace
- Removing write protection (Windows and Linux)
- Maintaining project structure

---

## Troubleshooting

### Common Issues

**Issue**: "Developer toolchain is needed for OCS"
- **Solution**: Ensure `rules_davinci_developer` toolchain is registered
- **Check**: `davinci_developer_cmd_label` (Linux) or `davinci_developer_path` (Windows)

**Issue**: "Cfg5 toolchain is needed for OCS"
- **Solution**: Ensure `rules_cfg5` toolchain is registered
- **Check**: `cfg5cli_path` must be set

**Issue**: "7z is needed under Windows"
- **Solution**: Define `seven_zip_toolchain` and register it
- **Install**: Download 7-Zip from https://www.7-zip.org/

**Issue**: OCS config files not found
- **Solution**: Verify `ocs_config_files` glob pattern matches files
- **Check**: Files must be in subdirectory with `/plugins/` in path

**Issue**: CreateProject.json path not updated
- **Solution**: Ensure JSON file named exactly "CreateProject.json"
- **Format**: Verify JSON structure matches expected format

**Issue**: Script task execution fails
- **Solution**: Verify `script_task` name matches task in script
- **Check**: Ensure script file is valid .jar or .dvgroovy
