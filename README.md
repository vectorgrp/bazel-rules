# Vector Bazel Rules

This repository contains the Vector Bazel Rules.

In general, it contains the necessary toolchains and custom rules to start running Vector tools such as DaVinci Team in a Bazel environment.

## Who should use these rules?

Everyone who wants to integrate Vector tools into their Bazel project.

Whether you are creating a large Bazel application or trying out Vector tools in a smaller Bazel project, these rules will streamline your tool integration workflow.

## Getting Started

In a `WORKSPACE` or `MODULE.bazel` file add an `http_archive` rule to fetch the ruleset:

```python
http_archive(
    name = "vector_bazel_rules",
    sha256 = "1234567891234567891234567891234567891234567891234567891234567891",
    url = "https://github.com/vectorgrp/bazel-rules/releases/download/<tag_version>/source<.zip|.tar.gz>",
)
```
Adapt `<tag_version>` to fetch a distinct release.

Make sure to use ```bazel skylib``` as well. See https://github.com/bazelbuild/bazel-skylib/releases for details.

## Rule & Toolchain Usage

Please refer to the appropriate ```rules``` folder for a detailed description in a README.md file.

## Current Limitations
We do not support vVirtualtarget (VTT) for our `DaVinci Configurator 5` and `DaVinci DvTeam` rules.

Support for vVirtualTarget (VTT) will be available in a future release of the Vector Bazel rules.

## Release

Some rules are interdependent, so all available rules and toolchains are published in one package.

## Bazel module

Currently we do not provide Bazel modules (bzlmod).
