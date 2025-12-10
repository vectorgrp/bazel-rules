# Creating a New Bazel Module

This guide walks through creating a new module in the `bazel-rules` repository.

## Prerequisites

- Bazel 8.1.1+ installed (see `.bazelversion`)
- Repository cloned locally
- Run `bazel run //:buildifier_check` to verify setup

## Step-by-Step Guide

### 1. Create Directory Structure

```
bcr-modules/modules/<module_name>/
├── BUILD.bazel                    # Module registry definition
├── <version>/                     # Version folder (e.g., 0.0.1/)
│   └── BUILD.bazel                # Version-specific build
└── srcs/                          # Source files
    ├── BUILD.bazel                # Exports for packaging
    ├── MODULE.bazel               # Bazel module metadata
    ├── defs.bzl                   # Public API exports
    └── private/                   # Implementation files
        └── *.bzl
```

### 2. Create Module Registry Definition

**File:** `bcr-modules/modules/<module_name>/BUILD.bazel`

```starlark
load("//bcr-modules/macros:add_module_macro.bzl", "module_bcr_dir")

package(default_visibility = ["//visibility:public"])

module_bcr_dir(
    name = "<module_name>",
    versions = [
        "0.0.1",
    ],
    visibility = ["//visibility:public"],
)
```

### 3. Create Version Build File

**File:** `bcr-modules/modules/<module_name>/0.0.1/BUILD.bazel`

```starlark
load("@rules_pkg//:mappings.bzl", "pkg_files")
load("//bcr-modules/macros:module_macro.bzl", "module")
load("//bcr-modules/macros:upload_macro.bzl", "module_upload")

package(default_visibility = ["//visibility:public"])

module_upload(
    name = "upload",
    archive = ":<module_name>",
    redeploy_if_exists = "true",
    upload_module_name = "<module_name>",
    version = "0.0.1",
)

# Group private implementation files
pkg_files(
    name = "private",
    srcs = [
        "//bcr-modules/modules/<module_name>/srcs:private/rules.bzl",
    ],
    prefix = "private",
)

# Group public API files
pkg_files(
    name = "public",
    srcs = [
        "//bcr-modules/modules/<module_name>/srcs:BUILD.bazel",
        "//bcr-modules/modules/<module_name>/srcs:MODULE.bazel",
        "//bcr-modules/modules/<module_name>/srcs:defs.bzl",
    ],
)

module(
    name = "<module_name>",
    additional_dependencies = [
        # Add dependencies in format: "dep_name@version"
        # Example: "rules_common@0.2.0",
    ],
    # integrity = "sha256-...",  # Add after first production upload
    module_version = "0.0.1",
    pkg_files_targets = [
        "public",
        "private",
    ],
)
```

### 4. Create Source Files

#### `srcs/BUILD.bazel`

```starlark
package(default_visibility = ["//visibility:public"])

exports_files([
    "BUILD.bazel",
    "MODULE.bazel",
    "defs.bzl",
    "private/rules.bzl",
])
```

#### `srcs/MODULE.bazel`

```starlark
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

module(
    name = "<module_name>",
    version = "0.0.1",
    compatibility_level = 0,
)

# Add bazel_dep() entries for dependencies
# bazel_dep(name = "rules_common", version = "0.2.0")
```

#### `srcs/defs.bzl`

```starlark
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

"""Public API for <module_name>"""

load("private/rules.bzl", _my_rule = "my_rule")

# Re-export public rules
my_rule = _my_rule
```

#### `srcs/private/rules.bzl`

```starlark
# MIT License
# ... (include full license header)

"""Implementation of <module_name> rules"""

def my_rule():
    """Your rule implementation here."""
    pass
```

### 5. Build and Validate

```bash
# Check formatting
bazel run //:buildifier_check

# Build the module archive
bazel build //bcr-modules/modules/<module_name>/0.0.1:<module_name>

# Query all generated targets
bazel query "//bcr-modules/modules/<module_name>/..."
```

### 6. Add to Registry

```bash
# Generate registry files and copy to vector-bazel-central-registry/
bazel run //bcr-modules/modules/<module_name>:<module_name>.add_to_repo
```

### 7. After Production Upload

Once the module is uploaded to production, get the integrity hash:

```bash
bazel run //bcr-modules/modules/<module_name>/0.0.1:upload.github_prod_get_archive_override
```

Add the `integrity` attribute to your `module()` call to speed up future builds.

## Checklist

- [ ] All `.bzl` files have MIT license header
- [ ] `versions` list in main `BUILD.bazel` includes new version
- [ ] `MODULE.bazel` version matches folder name
- [ ] `defs.bzl` exports all public rules
- [ ] `buildifier_check` passes
- [ ] Module builds successfully
- [ ] Registry updated via `.add_to_repo` target

## Reference Examples

- **Simple module**: `bcr-modules/modules/rules_common/`
- **With private files**: `bcr-modules/modules/rules_dvteam/`
- **With templates**: `bcr-modules/modules/rules_davinci_project/`
