Vector-Bazel-Rules

<a id="cfg5_toolchain"></a>

## cfg5_toolchain

<pre>
load("@//rules:defs.bzl", "cfg5_toolchain")

cfg5_toolchain(<a href="#cfg5_toolchain-name">name</a>, <a href="#cfg5_toolchain-cfg5_path">cfg5_path</a>, <a href="#cfg5_toolchain-cfg5cli_path">cfg5cli_path</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="cfg5_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="cfg5_toolchain-cfg5_path"></a>cfg5_path |  Mandatory path to the Cfg5 used in the bazel rules   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="cfg5_toolchain-cfg5cli_path"></a>cfg5cli_path |  Mandatory path to the Cfg5 cli path used in the bazel rules   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |