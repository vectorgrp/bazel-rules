# OCS
This chapter contains OCS related rules and toolchains documentation. 

## ocs

Usage in `BUILD.bazel` file:

<a id="ocs"></a>

## ocs

<pre>
load("@//rules:defs.bzl", "ocs")

ocs(<a href="#ocs-name">name</a>, <a href="#ocs-kwargs">kwargs</a>)
</pre>

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="ocs-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="ocs-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


<a id="create_ocs_app_deploy_rule"></a>

## create_ocs_app_deploy_rule

<pre>
load("@//rules:defs.bzl", "create_ocs_app_deploy_rule")

create_ocs_app_deploy_rule(<a href="#create_ocs_app_deploy_rule-name">name</a>, <a href="#create_ocs_app_deploy_rule-kwargs">kwargs</a>)
</pre>

Wraps the create_ocs_app_deploy_rule_internal with the private_is_windows select statement in place

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="create_ocs_app_deploy_rule-name"></a>name |  The unique name of this target   |  none |
| <a id="create_ocs_app_deploy_rule-kwargs"></a>kwargs |  All of the attrs of the create_ocs_app_deploy_rule_internal rule   |  none |

**RETURNS**

A create_ocs_app_deploy_rule_internal rule that contains the actual implementation

<a id="cfg5_execute_script_task"></a>

## cfg5_execute_script_task

<pre>
load("@//rules:defs.bzl", "cfg5_execute_script_task")

cfg5_execute_script_task(<a href="#cfg5_execute_script_task-name">name</a>, <a href="#cfg5_execute_script_task-kwargs">kwargs</a>)
</pre>


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cfg5_execute_script_task-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="cfg5_execute_script_task-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


<a id="seven_zip_toolchain"></a>

## seven_zip_toolchain

<pre>
load("@//rules:defs.bzl", "seven_zip_toolchain")

seven_zip_toolchain(<a href="#seven_zip_toolchain-name">name</a>, <a href="#seven_zip_toolchain-sevenzip_dir">sevenzip_dir</a>)
</pre>

When running under Windows, set the directory containing the local 7z.exe. Default is C:\Program Files\7-Zip. Not needed for Linux.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="seven_zip_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="seven_zip_toolchain-sevenzip_dir"></a>sevenzip_dir |  directory containing local 7z.exe under Windows   | String | optional |  `"C:\\Program Files\\7-Zip"`  |

# Example usage
The following showcases an example on how to use a rule and toolchain in your Bazel project environment.

## Fetching the rule

In a `WORKSPACE` or `MODULE.bazel` file add a `http_archive` rule to fetch the rule and toolchain:

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
    ocs(
        name = "custom-plugins",
        davinci_project_files = OCS_MODULECONFIG_PLUGINS_OUTPUT,
        dpa_file = "moduleConfig-plugins/StartApplication.dpa",
        ocs_app = "tools/ocs_env/ocs-custom/custom-app.jar",
        ocs_config_files = glob([
            "tools/ocs_env/ocs-custom/plugins/**/*.json",
        ]),
        result = OCS_CUSTOM_PLUGINS_OUTPUT + ["custom-plugins/StartApplication.dpa"],
    )
```