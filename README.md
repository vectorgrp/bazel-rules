# Vector Bazel Repository

A comprehensive Bazel monorepo for developing, building, and managing custom Bazel rules and modules used across Vector projects. This repository provides a streamlined workflow for creating custom modules, packaging them into archives, uploading to artifact registries, and maintaining a central module registry.

## Consumption of Vector Bazel rules

To consume the rules defined in this repository, you need to register the custom Bazel Central Registry (BCR) located in this repository.

**Configuration Steps:**

1.  **Update `.bazelrc`**: Add the following flag to your project's `.bazelrc` file to point Bazel to the registry directory and the Bazel Central Registry.

    ```properties
    common --registry=https://raw.githubusercontent.com/vectorgrp/bazel-rules/main/vector-bazel-central-registry
    common --registry=https://bcr.bazel.build
    ```

2.  **Add Dependencies**: In your `MODULE.bazel` file, declare the dependencies you need using `bazel_dep`.

    ```starlark
    bazel_dep(name = "rules_common", version = "0.2.0")
    ```

## Project Overview

This repository is structured around three main development areas:

### Core Components

- **`bcr-modules/`** - Custom Bazel module development and packaging
  - Contains module definitions, build configurations, and upload targets
  - Uses extensive Bazel macros for automated archive building and registry management
  - Recommended to use VS Code's Bazel Targets extension for managing build targets

- **`rules/`** - Custom Bazel rules development
  - Houses custom rule definitions and implementations
  - Used for developing reusable build logic across projects

- **`vector-bazel-central-registry/`** - Module registry management
  - Maintains the central registry of all custom modules
  - Automatically updated via Bazel targets - **do not edit manually**
  - Updates performed via: `bazel run [--//:BUILD_PROD_MODULES=True] //bcr-modules/modules/<module_name>:<module_name>.add_to_repo`
  - Use `--//:BUILD_PROD_MODULES=True` flag for production releases

### Supporting Infrastructure

- **`tools/`** - Custom scripts for module management and automation
- **`docs/`** - Comprehensive documentation and guides
- **`.github/`** - CI/CD configuration with GitHub Actions workflows

## Repository Structure

```
├── bcr-modules/                    # Module development and packaging
│   ├── macros/                     # Bazel macros for module automation
│   │   ├── add_module_macro.bzl    # Registry integration macro
│   │   ├── module_macro.bzl        # Module packaging macro
│   │   └── upload_macro.bzl        # Upload automation macro
│   ├── modules/                    # Individual module definitions
│   │   ├── rules_common/           # Example module
│   │   │   ├── 0.2.0/              # Version-specific configuration
│   │   │   ├── BUILD.bazel         # Module build definition
│   │   │   └── *.MODULE.bazel      # Module dependencies
│   │   └── [other modules]/
│   ├── rules/                      # Module build rules
│   └── BUILD.bazel.tpl             # Default BUILD file template
├── vector-bazel-central-registry/  # Central module registry
├── tools/                          # Management scripts
├── docs/                           # Documentation and guides
└── .github/                        # CI/CD configuration
```

## Rule Documentation

Comprehensive documentation for each Bazel module is available in its respective directory:

**User Documentation**: `bcr-modules/modules/<module_name>/README.md`

### Available Modules

- **rules_cfg5** - DaVinci Configurator 5 code generation
- **rules_common** - Common utilities for DaVinci tool integration
- **rules_davinci_developer** - DaVinci Developer toolchain
- **rules_dvteam** - DaVinci Team integration automation
- **rules_gradle** - Gradle toolchain and authentication
- **rules_ocs** - OCS execution and CFG5 script tasks

Each module's README.md contains installation instructions, usage examples, API reference and troubleshooting information.
