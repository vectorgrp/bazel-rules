# Vector Bazel Rules

This repository contains the Vector Bazel Rules.

In general it contains the necessary toolchains and custom rules to get started with executing Vector tools like DaVinci Team in a Bazel environment.

# Who should use these rules?

Everyone who wants to integrate Vector tools into their Bazel project. This will ease the integration effort.

Whether you're building a large-scale Bazel application or want to try Vector tools in a smaller Bazel project, these rules will streamline your workflow when integrating the tools.

# Usage

Use a [http_archive rule](https://bazel.build/rules/lib/repo/http#http_archive) in your project's WORKSPACE or MODULES.bazel file to let bazel fetch the rules and toolchains.


# Bazel module

Currently we do not provide Bazel modules (bzlmod).