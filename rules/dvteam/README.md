# DaVinci Team
This chapter contains DaVinci Team related rules and toolchains documentation. 

<a id="dvteam"></a>

## dvteam

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "dvteam")

dvteam(<a href="#dvteam-name">name</a>, <a href="#dvteam-kwargs">kwargs</a>)
</pre>

Wraps the dvteam with the private_is_windows select statement in place

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="dvteam-name"></a>name |  The unique name of this target   |  none |
| <a id="dvteam-kwargs"></a>kwargs |  All of the attrs of the dvteam rule   |  none |

**RETURNS**

A dvteam_def rule that contains the actual implementation

# Example usage
The following showcases an example on how to use a rule and toolchain in your Bazel project environment.

## Fetching the rule

In a `WORKSPACE` or `MODULE.bazel` file add an `http_archive` rule to fetch the rule and toolchain:

```python
http_archive(
    name = "vector_bazel_rules",
    sha256 = "1234567891234567891234567891234567891234567891234567891234567891",
    url = "https://github.com/vectorgrp/bazel-rules/archive/refs/tags/<tag_version>",
)
```
Adapt `<tag_version>` to fetch a distinct release.

## Instantiate the rule

In a `BUILD.bazel` file refer to the rule as follows:

```python
cfg5_generate_rt_workspace(
    name = "rt_generate", # Name of the Bazel target
    config_files = [ # Additional configuration files to start the cfg5 with
        "Config/AUTOSAR/PlatformTypes_AR4.arxml",
        "Config/VTT/Demo.vttmake",
        "Config/VTT/Demo.vttproj",
        "AnotherConfig/Config.arxml",
    ],
    config_folders = [ # List of config folders that the path will be checked for in each file to create a nested Config folder structure
        "Config",
        "AnotherConfig",
    ]
    dpa_file = ":FolderPath/ToDpaProject", # The folder path to your DPA project file (.dpa)
    genArgs = [ # List of command line argument the DaVinci Configurator 5 CLI supports
        "--help"
    ],
    generated_files = "FolderPath/ToGeneratedFiles/", # List of files which are output of this rule
    ,
    sip = "@external_repo//:package", # Path to the Microsar Classic product package
    target_compatible_with = [ # Platform definition for this target
        "//platforms:your_platform_definition",
    ],
)
```

## Configure the toolchain

In a `BUILD.bazel` file refer to the toolchain & platform configuration as follows:

```python
cfg5_toolchain(
    name = "cfg5_linux_impl",
    cfg5_files = "@ecu1sip//:DaVinci_Configurator_5",
    cfg5cli_path = "@ecu1sip//:DaVinciConfigurator/Core/DVCfgCmd",
)

toolchain(
    name = "cfg5_linux",
    exec_compatible_with = [
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
    ],
    toolchain = ":cfg5_linux_impl",
    toolchain_type = "@vector_bazel_rules//rules/cfg5:toolchain_type",
)
```
