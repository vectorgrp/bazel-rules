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

## Instantiate a rule

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

## Dependencies

The ```ocs``` rule depends on a couple of other rules and toolchains. 

The dotnet [Bazel rules for .NET](https://github.com/bazel-contrib/rules_dotnet/tree/master) is used for the execution of the rule under Linux.

In a ```MODULE.bazel``` file add this dependency as follows:

```python
      bazel_dep(name = "rules_dotnet", version = "0.17.5") # Tested with that version
      dotnet = use_extension("@rules_dotnet//dotnet:extensions.bzl", "dotnet")
      dotnet.toolchain(dotnet_version = "8.0.103") # Tested with that version
      use_repo(dotnet, "dotnet_toolchains")
```

The DaVinci Developer and DaVinci Configurator 5 toolchains are used for the execution of the ```ocs``` and ```cfg5_execute_script_task``` rules regardless of the OS.

In a `BUILD.bazel` file refer to the toolchain & platform configuration as follows:

### Execution under Linux

```python
    davinci_developer_toolchain(
        name = "davinci_developer_linux_impl",
        davinci_developer_label = "@davinci_developer_linux//:DEVImEx/bin/DVImEx", # External dependency to the DaVinci Developer CLI tool
    )

    toolchain(
        name = "davinci_developer_linux",
        exec_compatible_with = [
            "@platforms//os:linux",
        ],
        target_compatible_with = [
            "@platforms//os:linux",
        ],
        toolchain = ":davinci_developer_linux_impl",
        toolchain_type = "@vector_bazel_rules//rules/davinci_developer:toolchain_type",
    )

     cfg5_toolchain(
        name = "cfg5_linux_impl",
        cfg5_files = "@sip//:DaVinci_Configurator_5", # External dependency to the Microsar Classic product
        cfg5cli_path = "@sip//:DaVinciConfigurator/Core/DVCfgCmd", # External dependency to the DaVinci Configurator 5 CLI tool
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

### Execution under Windows

```python
    davinci_developer_toolchain(
      name = "davinci_developer_windows_impl",
      davinci_developer_path = "X:/Path/To/DaVinci_Developer_Classic/Vx_yz",
    )

    toolchain(
      name = "davinci_developer_windows",
      exec_compatible_with = [
          "@platforms//os:windows",
      ],
      target_compatible_with = [
          "@platforms//os:windows",
      ],
      toolchain = ":davinci_developer_windows_impl",
      toolchain_type = "@vector_bazel_rules//rules/davinci_developer:toolchain_type",
    )

    cfg5_toolchain(
        name = "cfg5_windows_impl",
        cfg5_files = "@sip//:DaVinci_Configurator_5", # External dependency to the Microsar Classic product
        cfg5_path = "@sip//:DaVinciConfigurator/Core/DaVinciCFG.exe", # External dependency to the DaVinci Configurator 5 GUI tool
        cfg5cli_path = "@sip//:DaVinciConfigurator/Core/DVCfgCmd.exe", # External dependency to the DaVinci Configurator 5 CLI tool
    )

    toolchain(
        name = "cfg5_windows",
        exec_compatible_with = [
            "@platforms//os:windows",
        ],
        target_compatible_with = [
            "@platforms//os:windows",
        ],
        toolchain = ":cfg5_windows_impl",
        toolchain_type = "@vector_bazel_rules//rules/cfg5:toolchain_type",
    )
```