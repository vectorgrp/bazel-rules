# Agent Instructions for bazel-rules Repository

## Repository Overview

This is the **Vector Bazel Rules** repository (`vectorgrp/bazel-rules` on GitHub), a comprehensive Bazel monorepo for developing, building, and managing custom Bazel rules and modules used across Vector projects.

**Current Modules:**
- `rules_cfg5`, `rules_common`, `rules_davinci_developer`, `rules_dvteam`, `rules_gradle`, `rules_ocs`

## Project Structure

### Core Components

1. **`bcr-modules/`** - Custom Bazel module development and packaging
   - Contains module definitions, build configurations, and upload targets
   - Uses extensive Bazel macros for automated archive building and registry management
   - Each module follows a standardized directory structure

2. **`bcr-modules/modules/`** - Individual module implementations
   - Current modules: `rules_cfg5`, `rules_common`, `rules_davinci_developer`, `rules_dvteam`, `rules_gradle`, `rules_ocs`
   - **Note**: More modules will be added as migration progresses

3. **`bcr-modules/macros/`** - Automation macros
   - `module_macro.bzl` - Module packaging and archive creation
   - `add_module_macro.bzl` - Registry integration
   - `upload_macro.bzl` - Upload automation for GitHub Releases

4. **`bcr-modules/rules/`** - Module build rules
   - `module.bzl`, `metadata_json.bzl`, `source_json.bzl`, `module_dot_bazel.bzl`

5. **`docs/`** - Documentation
   - `getting-started.md` - Getting started guide
   - `creating-new-module.md` - Step-by-step guide for creating new modules
   - `updating-module-version.md` - Guide for releasing new module versions
   - `toolchains.md` - Toolchain configuration examples

6. **`tools/`** - Shell scripts for module management
   - `add_module.sh`, `build_revisions_diff.sh`, `compare_modules.sh`, `get_archive_override.sh`

### Module Structure Pattern

Each module follows this structure:
```
bcr-modules/modules/<module_name>/
├── BUILD.bazel                      # Module definition using module_bcr_dir()
├── <module_name>.MODULE.bazel       # Module dependencies (optional)
├── <version>/                       # Version-specific folder
│   └── BUILD.bazel                  # Uses module() and module_upload() macros
└── srcs/                            # Source files for the module
    ├── BUILD.bazel
    ├── MODULE.bazel
    ├── defs.bzl                     # Public API exports
    ├── README.md
    └── private/                     # Implementation details
        └── *.bzl files
```

## Key Technologies and Dependencies

- **Bazel 8.1.1** (see `.bazelversion`)
- **Starlark** - Bazel's configuration language
- **rules_pkg** - For packaging archives
- **buildifier** - Code formatting and linting
- **Python 3.10+** - For some tooling
- **Java** - For bazel-diff tool

## Module Development Workflow

> **Detailed Guides:**
> - [Creating a New Module](../docs/creating-new-module.md) - Complete step-by-step with templates
> - [Updating Module Versions](../docs/updating-module-version.md) - Version release workflow

### Creating a New Module

1. **Create Directory Structure:**
   ```
   bcr-modules/modules/<module_name>/
   ├── BUILD.bazel
   ├── <version>/BUILD.bazel
   └── srcs/
   ```

2. **Define Module in `BUILD.bazel`:**
   ```starlark
   load("//bcr-modules/macros:add_module_macro.bzl", "module_bcr_dir")
   
   module_bcr_dir(
       name = "<module_name>",
       versions = ["<version>"],
       visibility = ["//visibility:public"],
   )
   ```

3. **Define Version-Specific Build in `<version>/BUILD.bazel`:**
   ```starlark
   load("//bcr-modules/macros:module_macro.bzl", "module")
   load("//bcr-modules/macros:upload_macro.bzl", "module_upload")
   
   module(
       name = "<module_name>",
       module_version = "<version>",
       srcs = glob(["**/*"]),
       third_party_prefix = "<prefix>",
       # integrity = "sha256-...",  # Add after first upload
   )
   
   module_upload(
       name = "upload",
       archive = ":<module_name>",
       upload_module_name = "<module_name>",
       version = "<version>",
   )
   ```

4. **Add Source Files in `srcs/`:**
   - `MODULE.bazel` - Module metadata
   - `defs.bzl` - Public API
   - `README.md` - Documentation
   - Implementation files in `private/`

### Building and Testing

```bash
# Build module archive
bazel build //bcr-modules/modules/<module_name>/<version>:<module_name>

# Run buildifier for formatting
bazel run //:buildifier_check

# Query module targets
bazel query "//bcr-modules/modules/<module_name>/..."
```

## Important Configuration Files

### `bcr-modules/urls.bzl`
Defines upload URLs for GitHub Releases:
```starlark
DEFAULT_PROD_GIT_UPLOAD_URL = "https://github.com/vectorgrp/bazel-rules/releases/download"
DEFAULT_DEV_GIT_UPLOAD_URL = "https://github.com/vectorgrp/bazel-rules/releases/download/staging"
```

### `MODULE.bazel`
Root module definition with dependencies including:
- `rules_cc`, `rules_java`, `rules_pkg`, `rules_python`
- `buildifier_prebuilt`, `stardoc`, `gazelle`
- `ape`, `aspect_rules_js`, `glib`, `bazel_skylib`

### `BUILD.bazel`
Root build file with:
- Buildifier targets for linting
- Gazelle for BUILD file generation
- Build settings for dev/prod module configuration

## Release Infrastructure

### GitHub Releases

Module archives are distributed via GitHub Releases:

**Release URL Structure:**
- **Production**: `https://github.com/vectorgrp/bazel-rules/releases/download/<module_name>/<version>/<module_name>.tar.gz`
- **Staging**: `https://github.com/vectorgrp/bazel-rules/releases/download/staging/<module_name>/<version>/<module_name>.tar.gz`

**Upload Targets:**
- `.github_staging` - Upload to staging releases
- `.github_prod` - Upload to production releases

**Infrastructure:**
- CI/CD via GitHub Actions (`.github/workflows/`)
- Authentication via `GITHUB_TOKEN`
- Registry updates automated via GitHub Actions

## License Information

- **Primary License**: MIT License
- **Exceptions**: 
  - `copy_file.bzl` - Apache License 2.0
  - Dependencies `rules_dotnet` and `rules_cc` - Apache License 2.0
- All source files in `bcr-modules/modules/*/srcs/` include MIT License headers

## Development Guidelines

### Code Style
- Use `buildifier` for Starlark formatting
- Follow existing module patterns
- Include comprehensive docstrings in `.bzl` files

### Module Naming
- Use prefix `rules_` for rule-based modules
- Use lowercase with underscores
- Be descriptive but concise

### Versioning
- Use semantic versioning: `MAJOR.MINOR.PATCH`
- Create new version directories for each release
- Update `versions` list in module's main `BUILD.bazel`

### Documentation
- Include `README.md` in module `srcs/`
- Document public APIs in `defs.bzl`
- Provide usage examples

### Testing
- Validate builds before committing
- Run buildifier checks
- Test module integration

## Common Commands

```bash
# Format Bazel files
bazel run //:buildifier_fix

# Check formatting
bazel run //:buildifier_check

# Build all modules
bazel build //bcr-modules/modules/...

# Query all module targets
bazel query "kind(module, //...)"

# List modules without integrity hashes
bazel query 'kind(source_json, //...) except attr(integrity, "sha256-", //...)'
```

## GitHub Actions Workflows

### Automatic Workflows
- **Validation** - Runs on all PRs and pushes to main
  - Buildifier formatting check
  - Module registry comparison
  - Integrity hash check (warning only)

- **Staging Release** - Runs when PR is merged to main
  - Automatically uploads new/modified modules to staging
  - Creates pre-releases with tag: `staging/<module_name>/<version>`
  - Validates upload URLs

- **Registry Update** - Runs after production releases
  - Generates module metadata
  - Commits to `vector-bazel-central-registry/`
  - Pushes to main branch

### Manual Workflows
- **Production Release** - Manually triggered via GitHub UI
  - Upload specific modules or all modules
  - Creates stable releases with tag: `<module_name>/<version>`
  - Triggers registry update on success

## Architecture Patterns

### Toolchain-Based Modules
Examples: `rules_cfg5`, `rules_davinci_developer`, `rules_gradle`, `rules_ocs`
- Define custom toolchains with `toolchain()` rule
- Implement toolchain providers
- Support platform-specific configurations (Linux/Windows)

### Rules Modules
Examples: `rules_common`, `rules_dvteam`, `rules_project`
- Provide reusable Bazel rules
- Export rules via `defs.bzl`
- Use `private/` directory for implementation details

### Common Patterns
- Template files in `templates/` subdirectories
- Python helpers in subdirectories (e.g., `pydpa/`)
- Platform-specific toolchain configurations
- Component reference systems for configurators

## External Dependencies

Key external repositories referenced:
- `@ape` - Utility tools
- `@rules_pkg` - Packaging functionality
- `@bazel_skylib` - Starlark utilities
- `@buildifier_prebuilt` - Code formatting
- `@stardoc` - Documentation generation
- `@gazelle` - BUILD file generation

## Agent Interaction Guidelines

When working with this repository:

1. **Module Patterns**: Follow existing module structure patterns precisely
3. **Build Before Modify**: Always build and test modules before suggesting changes
4. **Preserve Formatting**: Use buildifier for all Bazel file changes
5. **License Headers**: Maintain MIT license headers in new files (except where Apache 2.0 applies)
6. **Documentation**: Update README.md if adding new patterns or changing workflows
7. **Version Management**: Never modify existing version directories, always create new versions
8. **Registry Awareness**: Remember that `vector-bazel-central-registry` is auto-generated, don't manually edit

## Security

- Report vulnerabilities to: `support [at] vector.com`
- Follow responsible disclosure practices
- See `SECURITY.md` for details

## Contributing

**Current Status**: External contributions are not yet accepted
- See `CONTRIBUTING.md` for updates
- Contribution process is being established
- Pull requests are not currently being accepted
