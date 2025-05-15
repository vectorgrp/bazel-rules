# Bazel Toolchains

All toolchain configurations are typically configured within a `BUILD.bazel` file. 

## DaVinci Configurator 5 toolchains

### Execution under Linux

```python
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

## DaVinci Developer toolchains

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
```

## Gradle toolchains

### Execution under Linux

```python
        gradle_toolchain(
        name = "gradle_linux_impl",
        gradle_label = "@gradle//:bin/gradle",
        gradle_properties = "@gradle_properties//:gradle.properties",
    )

    toolchain(
        name = "gradle_linux",
        exec_compatible_with = [
            "@platforms//os:linux",
        ],
        target_compatible_with = [
            "@platforms//os:linux",
        ],
        toolchain = ":gradle_linux_impl",
        toolchain_type = "@vector_bazel_rules//rules/gradle:toolchain_type",
    )
```

### Execution under Windows

```python
    gradle_toolchain(
        name = "gradle_windows_impl",
        gradle_label = "@gradle//:bin/gradle.bat",
        gradle_properties = "@gradle_properties//:gradle.properties", # Instanciated in MODULE.bazel file
    )

    toolchain(
        name = "gradle_windows",
        exec_compatible_with = [
            "@platforms//os:windows",
        ],
        target_compatible_with = [
            "@platforms//os:windows",
        ],
        toolchain = ":gradle_windows_impl",
        toolchain_type = "@vector_bazel_rules//rules/gradle:toolchain_type",
    )
```