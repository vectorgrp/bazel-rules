# DaVinci Team
This chapter contains DaVinci Team related rules documentation. 

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
The following showcases an example on how to use a rule in your Bazel project environment.

## Fetching the rule

In a `WORKSPACE` or `MODULE.bazel` file add an `http_archive` rule to fetch the rule:

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
dvteam(
    name = "myintegrate-start-application", # Name of the Bazel target
    app_package_sources = [ # The additional app package sources that should be integrated
        "@myapplication//:package", 
    ],
    config_files = ["/path/to/myEcuC_BSW-x.armxl", # The expected output files of DaVinci Team
                    "/path/to/myEcuC_BSW-y.armxl",
                    "/path/to/myEcuC_BSW-z.armxl",
    ],
    dpa_file = "path/to/myproject.dpa", # The dpa file to use for the DvTeam run
    dvteam_args = [ # The arguments for the actual DvTeam CLI for the run
        "--debug",
        "--info",
    ],
    global_instruction_files = ["//path/to/xyz.mapping.json", # List of global instruction files. Depending on the instruction type, global instructions may be an addition to or have precedence over App Package specific instructions
    ], 
    gradle_file = "//path/to/build.gradle", # The build.gradle file to run DvTeam with
    java_keystore_file = "//path/to/java_keystore/file", # Java KeyStore file with root certificates
    results = ["/path/to/myproject_dvteam_task_name-x.zip", # The DvTeam run output files
               "/path/to/myproject_dvteam_task_name-y.zip",
               "/path/to/myproject_dvteam_task_name-z.zip",
    ],
    sip = "@mysip//path/to/bsw_modules", # Microsar Classic location to mark it as a dependency
    task = "myDvTeamTask", # The DvTeam task that will be run
    wfconfig = "//path/to/wfconfig.json", # The wfconfig file
)

```
