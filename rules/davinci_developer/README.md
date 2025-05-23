# DaVinci Developer
This chapter contains DaVinci Developer related toolchain documentation. 

<a id="davinci_developer_toolchain"></a>

## davinci_developer_toolchain

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "davinci_developer_toolchain")

davinci_developer_toolchain(<a href="#davinci_developer_toolchain-name">name</a>, <a href="#davinci_developer_toolchain-davinci_developer_cmd_label">davinci_developer_cmd_label</a>, <a href="#davinci_developer_toolchain-davinci_developer_label">davinci_developer_label</a>,
                            <a href="#davinci_developer_toolchain-davinci_developer_path">davinci_developer_path</a>)
</pre>

Either davinci_developer_label or davinci_developer_path have to be set for the toolchain to have any effect. This will then make the DaVinci Developer available via toolchain for rules like DaVinci Team

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="davinci_developer_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="davinci_developer_toolchain-davinci_developer_cmd_label"></a>davinci_developer_cmd_label |  Label version of the developer cmd that can be used if the DaVinci developer was downloaded via bazel, only used for linux   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="davinci_developer_toolchain-davinci_developer_label"></a>davinci_developer_label |  Label version of the developer path that can be used if the DaVinci developer was downloaded via bazel, mostly used for linux   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="davinci_developer_toolchain-davinci_developer_path"></a>davinci_developer_path |  Path version of the developer path that can be used if the DaVinci developer was not downloaded via bazel and is installed system wide, mostly used for windows   | String | optional |  `""`  |

# Example usage

The following showcases an example on how to use a toolchain in your Bazel project environment.

## Configure a toolchain

All toolchain configurations are typically configured within a `BUILD.bazel` file. 

Please see [DaVinci Developer toolchain definition](../toolchains.md#davinci-developer-toolchains).