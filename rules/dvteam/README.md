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

## Instantiate a rule

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
## Dependencies

The ```dvteam``` rule depends on a couple of other rules and toolchains. 

The dotnet [Bazel rules for .NET](https://github.com/bazel-contrib/rules_dotnet/tree/master) is used for the execution of the rule under Linux.

In a ```MODULE.bazel``` file add this dependency as follows:

```python
      bazel_dep(name = "rules_dotnet", version = "0.17.5") # Tested with that version
      dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
      dotnet.toolchain(dotnet_version = "8.0.103") # Tested with that version
      use_repo(dotnet, "dotnet_toolchains")
```

The `DaVinci Developer`, `DaVinci Configurator 5` and `gradle` toolchains are used for the execution of the ```dvteam``` rule regardless of the OS.

All toolchain configurations are typically configured within a `BUILD.bazel` file.

Please see [DaVinci Developer toolchain definition](../toolchains.md#davinci-developer-toolchains), [DaVinci Configurator 5 toolchain definition](../toolchains.md#davinci-configurator-5-toolchains) and [Gradle toolchain definition](../toolchains.md#gradle-toolchains).