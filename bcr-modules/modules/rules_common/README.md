# rules_common

## Overview

**Module Name:** `rules_common`  
**Current Version:** 0.2.0  
**Purpose:** Common utilities and helper functions for DaVinci tool integration with Bazel

### Description

The `rules_common` module provides shared functionality used by other DaVinci-related Bazel rule modules. It contains utilities for workspace creation, file operations, package merging, and downloading external resources. This module serves as a foundation for other rule sets like `rules_cfg5`, `rules_dvteam`, and `rules_ocs`.

### Key Functionality

- **Workspace Creation**: Helper functions to create isolated workspaces for DaVinci tools
- **File Operations**: Cross-platform file copying and manipulation utilities
- **Package Management**: Download, extract, and merge package functionality
- **Common Abstractions**: Shared code to reduce duplication across rule modules

---

## Module Structure

```
rules_common/
├── BUILD.bazel
├── 0.2.0/                          # Version directory
│   └── BUILD.bazel
└── srcs/                           # Source files
    ├── BUILD.bazel
    ├── MODULE.bazel
    ├── copy_file.bzl               # File copying utilities
    ├── create_davinci_tool_workspace.bzl  # Workspace creation
    ├── download_and_merge.bzl      # Package download/merge
    ├── extract.bzl                 # Archive extraction
    └── merge_packages.bzl          # Package merging utilities
```

---

## Functions and Utilities

### create_davinci_tool_workspace

**Location:** `create_davinci_tool_workspace.bzl`

Creates a separate workspace in the bazel-bin directory for DaVinci tool execution. This copies all configuration files and optionally provided files (like .dpa projects) into an isolated environment.

**Signature:**
```python
create_davinci_tool_workspace(
    ctx,
    workspace_name,
    addtional_workspace_files = [],
    is_windows = False,
    config_files = [],
    config_folders = ["Config"]
)
```

**Parameters:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `ctx` | Context | Current rule context creating the workspace | Yes | - |
| `workspace_name` | String | Name for the created workspace | Yes | - |
| `addtional_workspace_files` | List[File] | Additional files to add to workspace (e.g., .dpa files) | No | `[]` |
| `is_windows` | Boolean | Whether execution is on Windows platform | No | `False` |
| `config_files` | List[File] | List of configuration files for the workspace | No | `[]` |
| `config_folders` | List[String] | Config folder names to check in file paths for nesting | No | `["Config"]` |

**Returns:**
`DaVinciToolWorkspaceInfo` struct containing:
- `files`: List of config files in workspace
- `workspace_prefix`: Workspace name
- `addtional_workspace_files`: Copied additional files

**Usage Example:**
```python
workspace = create_davinci_tool_workspace(
    ctx,
    workspace_name = "my_tool_workspace",
    addtional_workspace_files = [ctx.file.dpa_file],
    is_windows = ctx.attr.private_is_windows,
    config_files = ctx.files.config_files
)
```

---

### copy_file

**Location:** `copy_file.bzl`

Cross-platform file copying utility that handles differences between Windows and Linux.

**Signature:**
```python
copy_file(ctx, src, dst, is_windows = False)
```

**Parameters:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `ctx` | Context | Current rule context | Yes | - |
| `src` | File | Source file to copy | Yes | - |
| `dst` | File | Destination file path | Yes | - |
| `is_windows` | Boolean | Whether to use Windows copy commands | No | `False` |

**Implementation Details:**
- Linux: Uses `cp -f` command
- Windows: Generates `.bat` file with `copy /Y` command
- Handles readonly file restrictions in Bazel output directories

---

### download_and_merge

**Location:** `download_and_merge.bzl`

Repository rule for downloading and merging multiple packages.

**Usage in MODULE.bazel:**
```python
download_and_merge = use_repo_rule("@rules_common//:download_and_merge.bzl", "download_and_merge")

download_and_merge(
    name = "merged_packages",
    urls = [
        "https://example.com/package1.zip",
        "https://example.com/package2.zip",
    ],
    sha256 = {
        "package1.zip": "abc123...",
        "package2.zip": "def456...",
    },
)
```

---

### extract

**Location:** `extract.bzl`

Utilities for extracting archives (zip, tar, etc.).

---

### merge_packages

**Location:** `merge_packages.bzl`

Functions to merge multiple packages into a single directory structure.

---

## Dependencies

This module depends on:
- `bazel_skylib` (version 1.7.1)
- `ape` (version 1.0.1)

**Add in MODULE.bazel:**
```python
bazel_dep(name = "rules_common", version = "0.2.0")
```

---

## Platform Support

- **Linux**: Full support
- **Windows**: Full support
- **Cross-platform**: Utilities automatically detect and adapt to platform

---

## Limitations

- File copying creates copies to workaround Bazel's readonly restrictions on action outputs
- Config folder structure assumes specific naming conventions (default "Config" folder)
- Workspace creation happens in bazel-bin directory
