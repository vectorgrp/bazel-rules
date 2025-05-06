# OCS
This chapter contains OCS related rules documentation. 

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



<a id="cfg5_execute_script_task"></a>

## cfg5_execute_script_task

Usage in `BUILD.bazel` file:

<pre>
load("@//rules:defs.bzl", "cfg5_execute_script_task")

cfg5_execute_script_task(<a href="#cfg5_execute_script_task-name">name</a>, <a href="#cfg5_execute_script_task-kwargs">kwargs</a>)
</pre>

**PARAMETERS**

| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="cfg5_execute_script_task-name"></a>name |  <p align="center"> - </p>   |  none |
| <a id="cfg5_execute_script_task-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


# Example usage
The following showcases an example on how to use a rule in your Bazel project environment.

## Fetching the rule

In a `WORKSPACE` or `MODULE.bazel` file add a `http_archive` rule to fetch the rule:

```python
http_archive(
    name = "vector_bazel_rules",
    sha256 = "1234567891234567891234567891234567891234567891234567891234567891",
    url = "https://github.com/vectorgrp/bazel-rules/archive/refs/tags/<tag_version>",
)
```
Adapt `<tag_version>` to fetch a distinct release.

## Instantiate the rule

In a `BUILD.bazel` file refer to the rules as follows:

```python
    ocs(
        name = "mycustom-plugins", # Name of the Bazel target
        davinci_project_files = ["/path/to/myproject_files", # Project files if a project is modified
        ],
        dpa_file = "path/to/myproject.dpa", # The dpa file if a project is modified and not created
        ocs_app = "path/to/myocs-app.jar", # The .jar file of the ocs app
        ocs_config_files = glob([ # The ocs plugin json files from ocs home directory
            "path/to/myconfig.json",
        ]),
        result = ["/path/to/output", # OCS run output files
        ],
    )
```

```python
    cfg5_execute_script_task(
        name = "execute-my-script", # Name of the Bazel target
        davinci_project_files = ["/path/to/myproject_files", # Project files if a project is modified
        ],
        dpa_file = "path/to/myproject.dpa", # The dpa project file
        script_task = "myscript-task", # Name of the script task
        script = "//path/to/my-script.jar", # The .jar or .dvgroovy file
        result = ["/path/to/output", # The run output files
        ],
    )
```