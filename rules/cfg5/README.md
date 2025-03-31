# DaVinci Configurator 5
This chapter contains DaVinci Configurator 5 related rules and toolchains documentation. 

## cfg5_toolchain

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "cfg5_toolchain")

cfg5_toolchain(<a href="#cfg5_toolchain-name">name</a>, <a href="#cfg5_toolchain-cfg5_files">cfg5_files</a>, <a href="#cfg5_toolchain-cfg5_path">cfg5_path</a>, <a href="#cfg5_toolchain-cfg5cli_path">cfg5cli_path</a>)
</pre>


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cfg5_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cfg5_toolchain-cfg5_files"></a>cfg5_files |  Optional cfg5 files used as input for hermiticity   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="cfg5_toolchain-cfg5_path"></a>cfg5_path |  Path to the Cfg5 used in the bazel rules   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="cfg5_toolchain-cfg5cli_path"></a>cfg5cli_path |  Mandatory path to the Cfg5 cli path used in the bazel rules   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


## start_cfg5_windows

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "start_cfg5_windows")

start_cfg5_windows(<a href="#start_cfg5_windows-name">name</a>, <a href="#start_cfg5_windows-cfg5_args">cfg5_args</a>, <a href="#start_cfg5_windows-dpa">dpa</a>)
</pre>


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="start_cfg5_windows-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="start_cfg5_windows-cfg5_args"></a>cfg5_args |  Additional CFG5 arguments   | String | optional |  `""`  |
| <a id="start_cfg5_windows-dpa"></a>dpa |  The dpa file to start the CFG5 with   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


## cfg5_generate_rt

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "cfg5_generate_rt")

cfg5_generate_rt(<a href="#cfg5_generate_rt-name">name</a>, <a href="#cfg5_generate_rt-kwargs">kwargs</a>)
</pre>

Wraps the cfg5_generate_rt with the private_is_windows select statement in place


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cfg5_generate_rt-name"></a>name |  The unique name of this target   |  none |
| <a id="cfg5_generate_rt-kwargs"></a>kwargs |  All of the attrs of the cfg5_generate_rt rule   |  none |


**RETURNS**

A cfg5_generate_rt_workspace_def rule that contains the actual implementation


## cfg5_generate_rt_workspace

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "cfg5_generate_rt_workspace")

cfg5_generate_rt_workspace(<a href="#cfg5_generate_rt_workspace-name">name</a>, <a href="#cfg5_generate_rt_workspace-kwargs">kwargs</a>)
</pre>

Wraps the cfg5_generate_rt_workspace with the private_is_windows select statement in place


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cfg5_generate_rt_workspace-name"></a>name |  The unique name of this target   |  none |
| <a id="cfg5_generate_rt_workspace-kwargs"></a>kwargs |  All of the attrs of the cfg5_generate_rt_workspace rule   |  none |


**RETURNS**

A cfg5_generate_rt_workspace_def rule that contains the actual implementation


## cfg5_generate_vtt

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "cfg5_generate_vtt")

cfg5_generate_vtt(<a href="#cfg5_generate_vtt-name">name</a>, <a href="#cfg5_generate_vtt-kwargs">kwargs</a>)
</pre>

Wraps the cfg5_generate_vtt with the private_is_windows select statement in place


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cfg5_generate_vtt-name"></a>name |  The unique name of this target   |  none |
| <a id="cfg5_generate_vtt-kwargs"></a>kwargs |  All of the attrs of the cfg5_generate_vtt rule   |  none |


**RETURNS**

A cfg5_generate_vtt_def rule that contains the actual implementation


## cfg5_generate_vtt_workspace

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "cfg5_generate_vtt_workspace")

cfg5_generate_vtt_workspace(<a href="#cfg5_generate_vtt_workspace-name">name</a>, <a href="#cfg5_generate_vtt_workspace-kwargs">kwargs</a>)
</pre>

Wraps the cfg5_generate_vtt_workspace with the private_is_windows select statement in place


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cfg5_generate_vtt_workspace-name"></a>name |  The unique name of this target   |  none |
| <a id="cfg5_generate_vtt_workspace-kwargs"></a>kwargs |  All of the attrs of the cfg5_generate_vtt_workspace rule   |  none |


**RETURNS**

A cfg5_generate_vtt_workspace_def rule that contains the actual implementation


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
