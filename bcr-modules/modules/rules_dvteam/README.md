# rules_dvteam

## Overview

**Module Name:** `rules_dvteam`  
**Current Version:** 0.0.1  
**Purpose:** Bazel rules for Vector's DaVinci Team (DVTeam) integration and automation

### Description

The `rules_dvteam` module provides Bazel integration for Vector's DaVinci Team tool, which automates the integration of software applications into AUTOSAR Basic Software (BSW) projects. DVTeam uses Gradle as its execution engine and integrates with DaVinci Developer, DaVinci Configurator 5, and VTT (Virtual Target Time) tools.

### Key Functionality

- **DVTeam Execution**: Run DaVinci Team integration tasks within Bazel builds
- **App Package Integration**: Integrate application packages into BSW configurations
- **Gradle Integration**: Execute Gradle-based DVTeam workflows
- **Multi-Tool Coordination**: Coordinates DaVinci Developer, CFG5, Gradle, and VTT toolchains
- **Configuration Management**: Handle complex AUTOSAR configuration workflows
- **Cross-Platform**: Windows and Linux support with platform-specific execution

---

## Module Structure

```
rules_dvteam/
 BUILD.bazel
 README.md
 0.0.1/                          # Version 0.0.1 (current)
   └── BUILD.bazel
 srcs/                           # Source files
    ├── BUILD.bazel
    ├── MODULE.bazel
    ├── defs.bzl                    # Public API
    └── private/
        └── rules.bzl               # DVTeam rule implementation
```

---

## Rules and Functions

### dvteam

Executes DaVinci Team integration tasks using Gradle and Vector toolchains.

**Location:** `private/rules.bzl` (exported via `defs.bzl`)

**Signature:**
```python
dvteam(
    name,
    dpa_file,
    gradle_file,
    task,
    wfconfig,
    results,
    sip,
    app_package_sources = [],
    config_files = [],
    config_folders = ["Config"],
    dvteam_args = [],
    global_instruction_files = [],
    custom_scripts = [],
    java_keystore_file = None,
    java_keystore_password = "changeit"
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `dpa_file` | Label | DaVinci project (.dpa) file | Yes | - |
| `gradle_file` | Label | Gradle build file for DVTeam | Yes | - |
| `task` | String | Gradle task to execute | Yes | - |
| `wfconfig` | Label | Workflow configuration JSON file | Yes | - |
| `results` | List[Output] | Expected output files from DVTeam | Yes | - |
| `sip` | Label | SIP (Software Integration Platform) location | Yes | - |
| `app_package_sources` | List[Label] | App packages to integrate | No | `[]` |
| `config_files` | List[Label] | Configuration files (.arxml, .xml, etc.) | No | `[]` |
| `config_folders` | List[String] | Config folder names for workspace structure | No | `["Config"]` |
| `dvteam_args` | List[String] | Additional DVTeam CLI arguments | No | `[]` |
| `global_instruction_files` | List[Label] | Global instruction JSON files | No | `[]` |
| `custom_scripts` | List[Label] | Custom DVGroovy scripts | No | `[]` |
| `java_keystore_file` | Label | Java KeyStore file with certificates | No | `None` |
| `java_keystore_password` | String | Java KeyStore password | No | `"changeit"` |

**Usage Example:**
```python
load("@rules_dvteam//:defs.bzl", "dvteam")

dvteam(
    name = "integrate_application",
    dpa_file = "project/EcuBsw.dpa",
    gradle_file = "integration/build.gradle",
    task = "IntegrateApplication",
    wfconfig = "integration/wfconfig.json",
    sip = "@microsar_classic//:bsw_modules",
    app_package_sources = [
        "@my_application//:package",
        "@my_diagnostics//:package",
    ],
    config_files = glob([
        "Config/**/*.arxml",
        "Config/**/*.xml",
    ]),
    global_instruction_files = [
        "integration/global_mapping.json",
    ],
    results = [
        "GenData/EcuBsw_IntegratedConfig.arxml",
        "GenData/EcuBsw_DiagnosticConfig.arxml",
    ],
    dvteam_args = [
        "--debug",
        "--info",
    ],
)

# Use integrated configuration in code generation
load("@rules_cfg5//:defs.bzl", "cfg5_generate_rt")

cfg5_generate_rt(
    name = "bsw_gen",
    dpa_file = "project/EcuBsw.dpa",
    config_files = [":integrate_application"],
    # ... other attributes
)
```

---

## Usage Guide

### Setup DVTeam Environment

1. **Add module dependencies in MODULE.bazel:**
```python
bazel_dep(name = "rules_dvteam", version = "0.0.1")
bazel_dep(name = "rules_davinci_developer", version = "0.0.1")
bazel_dep(name = "rules_cfg5", version = "0.0.3")
bazel_dep(name = "rules_gradle", version = "0.0.1")
bazel_dep(name = "rules_common", version = "0.2.0")

# Required for Linux execution
bazel_dep(name = "rules_dotnet", version = "0.17.5")
dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
dotnet.toolchain(dotnet_version = "8.0.103")
use_repo(dotnet, "dotnet_toolchains")
```

2. **Define all required toolchains in BUILD.bazel:**
```python
load("@rules_davinci_developer//:toolchains.bzl", "davinci_developer_toolchain")
load("@rules_cfg5//:defs.bzl", "cfg5_toolchain")
load("@rules_gradle//:defs.bzl", "gradle_toolchain")

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

# Gradle toolchain
gradle_toolchain(
    name = "gradle_toolchain_impl",
    gradle_label = "@gradle_dist//:gradle",
)

toolchain(
    name = "gradle_toolchain",
    toolchain = ":gradle_toolchain_impl",
    toolchain_type = "@rules_gradle//:toolchain_type",
)
```

3. **Register toolchains in MODULE.bazel:**
```python
register_toolchains(
    "//toolchains:davinci_developer_toolchain",
    "//toolchains:cfg5_toolchain",
    "//toolchains:gradle_toolchain",
)
```
