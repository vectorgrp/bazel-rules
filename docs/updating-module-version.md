# Updating a Module Version

This guide explains how to release a new version of an existing module.

## Important Rules

1. **Never modify existing version directories** - always create a new version
2. **Use semantic versioning** - `MAJOR.MINOR.PATCH`
3. **Update the versions list** - in the module's main `BUILD.bazel`

## Step-by-Step Guide

### 1. Create New Version Directory

Copy the latest version directory as a starting point:

```bash
cd bcr-modules/modules/<module_name>
cp -r 0.0.1 0.0.2
```

### 2. Update Version Build File

**File:** `bcr-modules/modules/<module_name>/0.0.2/BUILD.bazel`

Update all version references:

```starlark
load("@rules_pkg//:mappings.bzl", "pkg_files")
load("//bcr-modules/macros:module_macro.bzl", "module")
load("//bcr-modules/macros:upload_macro.bzl", "module_upload")

package(default_visibility = ["//visibility:public"])

module_upload(
    name = "upload",
    archive = ":<module_name>",
    upload_module_name = "<module_name>",
    version = "0.0.2",  # ← Update version
)

# ... pkg_files definitions stay the same ...

module(
    name = "<module_name>",
    additional_dependencies = [
        # Update dependency versions if needed
    ],
    # integrity = "...",  # ← REMOVE integrity for new version
    module_version = "0.0.2",  # ← Update version
    pkg_files_targets = [
        "public",
        "private",
    ],
)
```

**Critical:** Remove the `integrity` attribute when creating a new version. Add it back after the first production upload.

### 3. Update Source Files

#### `srcs/MODULE.bazel`

Update the version in the module declaration:

```starlark
module(
    name = "<module_name>",
    version = "0.0.2",  # ← Update version
    compatibility_level = 0,
)

# Update bazel_dep versions if needed
bazel_dep(name = "rules_common", version = "0.2.0")
```

#### Source Code Changes

Make your actual code changes in `srcs/` and `srcs/private/`.

### 4. Update Module Registry Definition

**File:** `bcr-modules/modules/<module_name>/BUILD.bazel`

Add the new version to the `versions` list:

```starlark
load("//bcr-modules/macros:add_module_macro.bzl", "module_bcr_dir")

package(default_visibility = ["//visibility:public"])

module_bcr_dir(
    name = "<module_name>",
    versions = [
        "0.0.1",
        "0.0.2",  # ← Add new version
    ],
    visibility = ["//visibility:public"],
)
```

### 5. Build and Validate

```bash
# Check formatting
bazel run //:buildifier_check

# Build the new version
bazel build //bcr-modules/modules/<module_name>/0.0.2:<module_name>

# Verify all targets
bazel query "//bcr-modules/modules/<module_name>/..."
```

### 6. Update Registry

```bash
# For development/staging URLs (default)
bazel run //bcr-modules/modules/<module_name>:<module_name>.add_to_repo

# For production URLs (after production release)
bazel run --//:BUILD_PROD_MODULES=True //bcr-modules/modules/<module_name>:<module_name>.add_to_repo
```

This updates `vector-bazel-central-registry/modules/<module_name>/` with:
- Updated `metadata.json` (includes new version)
- New `0.0.2/` directory with `MODULE.bazel` and `source.json`

> **Note:** Use `--//:BUILD_PROD_MODULES=True` when updating the registry after production releases to ensure production URLs are used.

### 7. Post-Upload: Add Integrity Hash

After the module is uploaded to production GitHub Releases:

```bash
bazel run //bcr-modules/modules/<module_name>/0.0.2:upload.github_prod_get_archive_override
```

Copy the `integrity` value and add it to `0.0.2/BUILD.bazel`:

```starlark
module(
    name = "<module_name>",
    integrity = "sha256-ABC123...",  # ← Add after upload
    module_version = "0.0.2",
    # ...
)
```

## Version Update Checklist

- [ ] New version directory created (don't modify old versions)
- [ ] `module_upload` version updated
- [ ] `module` version updated  
- [ ] `integrity` removed (for new version)
- [ ] `srcs/MODULE.bazel` version updated
- [ ] Main `BUILD.bazel` versions list updated
- [ ] Code changes made in `srcs/`
- [ ] `buildifier_check` passes
- [ ] Module builds successfully
- [ ] Registry updated via `.add_to_repo`
- [ ] After upload: `integrity` hash added back

## Dependency Version Updates

When updating dependencies:

1. Update `bazel_dep()` in `srcs/MODULE.bazel`
2. Update `additional_dependencies` in version `BUILD.bazel`:

```starlark
module(
    name = "<module_name>",
    additional_dependencies = [
        "rules_common@0.3.0",  # ← Updated dependency
    ],
    # ...
)
```

## Breaking Changes (Major Version)

For breaking changes, increment the major version and consider:

1. Updating `compatibility_level` in `srcs/MODULE.bazel`
2. Documenting migration steps in module's README
3. Maintaining backward compatibility where possible

## Example: `rules_davinci_project` 0.0.1 → 0.0.2

See the actual version update:
- Old: `bcr-modules/modules/rules_davinci_project/0.0.1/BUILD.bazel`
- New: `bcr-modules/modules/rules_davinci_project/0.0.2/BUILD.bazel`
- Registry: `bcr-modules/modules/rules_davinci_project/BUILD.bazel` (versions list)
