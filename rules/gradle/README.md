# Gradle
This chapter contains Gradle related rules and toolchains documentation. This rules and toolchains are adapted to fit the needs for our Vector products which rely on gradle.

<a id="generate_gradle_properties"></a>

## generate_gradle_properties

<pre>
load("@//rules:defs.bzl", "generate_gradle_properties")

generate_gradle_properties(<a href="#generate_gradle_properties-name">name</a>, <a href="#generate_gradle_properties-gradle_properties_content">gradle_properties_content</a>, <a href="#generate_gradle_properties-netrc">netrc</a>, <a href="#generate_gradle_properties-repo_mapping">repo_mapping</a>, <a href="#generate_gradle_properties-tokens">tokens</a>)
</pre>

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="generate_gradle_properties-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="generate_gradle_properties-gradle_properties_content"></a>gradle_properties_content |  The content of the gradle.properties file before the tokens are added to it   | String | optional |  `""`  |
| <a id="generate_gradle_properties-netrc"></a>netrc |  Location of the .netrc file to use for authentication   | String | optional |  `""`  |
| <a id="generate_gradle_properties-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |
| <a id="generate_gradle_properties-tokens"></a>tokens |  Map between tokens to generate and their respective url in the .netrc file   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |

<a id="gradle_toolchain"></a>

## gradle_toolchain

<pre>
load("@//rules:defs.bzl", "gradle_toolchain")

gradle_toolchain(<a href="#gradle_toolchain-name">name</a>, <a href="#gradle_toolchain-gradle_label">gradle_label</a>, <a href="#gradle_toolchain-gradle_path">gradle_path</a>, <a href="#gradle_toolchain-gradle_properties">gradle_properties</a>)
</pre>

Simple gradle toolchain that is used for DaVinciTeam rules and others that rely on gradle

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="gradle_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="gradle_toolchain-gradle_label"></a>gradle_label |  Optional label version of the gradle path, usually used when gradle is downloaded as an external package with bazel   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="gradle_toolchain-gradle_path"></a>gradle_path |  Optional path version of the gradle path, usually used when gradle is NOT downloaded as an external package with bazel   | String | optional |  `""`  |
| <a id="gradle_toolchain-gradle_properties"></a>gradle_properties |  optional gradle properties to use other than the default system one   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |





# Example usage
The following showcases an example on how to use a rule and toolchain in your Bazel project environment.

## Instantiate a rule

In a `BUILD.bazel` file refer to the rule as follows:

```python

```

## Configure a toolchain

In a `BUILD.bazel` file refer to the toolchain & platform configuration as follows:

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
        gradle_properties = "@gradle_properties//:gradle.properties",
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

