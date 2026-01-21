# rules_gradle

## Overview

**Module Name:** `rules_gradle`  
**Current Version:** 0.0.1  
**Purpose:** Gradle toolchain and authentication utilities for Bazel builds

### Description

The `rules_gradle` module provides Bazel integration for Gradle build tool, specifically adapted for Vector's DaVinci tools that rely on Gradle. It includes toolchain definitions for Gradle execution and repository rules for generating Gradle properties files with authentication tokens from .netrc files.

### Key Functionality

- **Gradle Toolchain**: Define and use Gradle installations in Bazel builds
- **Authentication Management**: Generate gradle.properties with tokens from .netrc
- **Properties Generation**: Create Gradle properties files dynamically
- **Cross-Platform**: Windows and Linux support (path-based and label-based)
- **Integration**: Used by rules_dvteam and other Gradle-dependent rules

---

## Module Structure

```
rules_gradle/
 BUILD.bazel
 README.md
 0.0.1/                          # Version 0.0.1 (current)
   └── BUILD.bazel
 srcs/                           # Source files
    ├── BUILD.bazel
 MODULE.bazel    
    ├── defs.bzl                    # Public API
    └── private/
        ├── rules.bzl               # Repository rule for properties generation
        └── toolchains.bzl          # Gradle toolchain definition
```

---

## Rules and Functions

### gradle_toolchain

Defines a Gradle toolchain for use in Bazel builds.

**Location:** `private/toolchains.bzl`

**Signature:**
```python
gradle_toolchain(
    name,
    gradle_label = None,
    gradle_path = "",
    gradle_properties = None
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | Name | Unique name for this target | Yes | - |
| `gradle_label` | Label | Label to Gradle executable (when downloaded via Bazel) | No | `None` |
| `gradle_path` | String | System path to Gradle (when installed system-wide) | No | `""` |
| `gradle_properties` | Label | Custom gradle.properties file | No | `None` |

**Usage Example - Linux (Label-based):**
```python
load("@rules_gradle//:defs.bzl", "gradle_toolchain")

# Download Gradle distribution
http_archive(
    name = "gradle_dist",
    url = "https://services.gradle.org/distributions/gradle-8.5-bin.zip",
    sha256 = "...",
    build_file_content = """
filegroup(
    name = "gradle",
    srcs = ["gradle-8.5/bin/gradle"],
    visibility = ["//visibility:public"],
)
""",
)

gradle_toolchain(
    name = "gradle_toolchain_impl",
    gradle_label = "@gradle_dist//:gradle",
    gradle_properties = "@gradle_properties//:gradle.properties",
)

toolchain(
    name = "gradle_toolchain",
    exec_compatible_with = ["@platforms//os:linux"],
    target_compatible_with = ["@platforms//os:linux"],
    toolchain = ":gradle_toolchain_impl",
    toolchain_type = "@rules_gradle//:toolchain_type",
)
```

**Usage Example - Windows (Path-based):**
```python
load("@rules_gradle//:defs.bzl", "gradle_toolchain")

gradle_toolchain(
    name = "gradle_toolchain_impl",
    gradle_path = "C:/Gradle/gradle-8.5/bin/gradle.bat",
    gradle_properties = "@gradle_properties//:gradle.properties",
)

toolchain(
    name = "gradle_toolchain",
    exec_compatible_with = ["@platforms//os:windows"],
    toolchain = ":gradle_toolchain_impl",
    toolchain_type = "@rules_gradle//:toolchain_type",
)
```

---

### generate_gradle_properties

Repository rule that generates a gradle.properties file with authentication tokens from .netrc.

**Location:** `private/rules.bzl`

**Signature:**
```python
generate_gradle_properties(
    name,
    tokens,
    netrc = "",
    gradle_properties_content = ""
)
```

**Attributes:**

| Name | Type | Description | Required | Default |
|------|------|-------------|----------|---------|
| `name` | String | Repository name | Yes | - |
| `tokens` | Dict[String, String] | Map of token names to .netrc URLs | Yes | - |
| `netrc` | String | Path to .netrc file (if not using default) | No | `""` |
| `gradle_properties_content` | String | Base content for gradle.properties | No | `""` |

**Usage in MODULE.bazel:**
```python
generate_gradle_properties = use_repo_rule("@rules_gradle//:defs.bzl", "generate_gradle_properties")

generate_gradle_properties(
    name = "gradle_properties",
    tokens = {
        "vector.artifactory.user": "artifactory.vector.com",
        "vector.artifactory.password": "artifactory.vector.com",
        "vector.nexus.token": "nexus.vector.com",
    },
    gradle_properties_content = """
org.gradle.daemon=false
org.gradle.caching=false
""",
)
```

**How It Works:**
1. Reads .netrc file (from `netrc` attribute, `$NETRC` env var, or `~/.netrc`)
2. Extracts passwords for specified URLs from .netrc
3. Generates gradle.properties with tokens: `<token_name>=<password>`
4. Includes base content from `gradle_properties_content`

**Example .netrc:**
```
machine artifactory.vector.com
  login myuser
  password my_secret_token

machine nexus.vector.com
  login api_token
  password another_secret_token
```

**Generated gradle.properties:**
```
org.gradle.daemon=false
org.gradle.caching=false
vector.artifactory.user=myuser
vector.artifactory.password=my_secret_token
vector.nexus.token=another_secret_token
```

---

## Usage Guide

### Setup Gradle Toolchain

1. **Add module dependency in MODULE.bazel:**
```python
bazel_dep(name = "rules_gradle", version = "0.0.1")
```

2. **Generate gradle.properties with authentication:**
```python
generate_gradle_properties = use_repo_rule("@rules_gradle//:defs.bzl", "generate_gradle_properties")

generate_gradle_properties(
    name = "gradle_properties",
    tokens = {
        "artifactoryUser": "artifactory.example.com",
        "artifactoryPassword": "artifactory.example.com",
    },
)
```

3. **Define Gradle toolchain:**
```python
load("@rules_gradle//:defs.bzl", "gradle_toolchain")

gradle_toolchain(
    name = "my_gradle_toolchain",
    gradle_label = "@gradle_dist//:gradle",
    gradle_properties = "@gradle_properties//:gradle.properties",
)

toolchain(
    name = "gradle_toolchain",
    toolchain = ":my_gradle_toolchain",
    toolchain_type = "@rules_gradle//:toolchain_type",
)
```

4. **Register toolchain:**
```python
register_toolchains("//toolchains:gradle_toolchain")
```

### Use in Rules

Rules can access Gradle toolchain:

```python
def _my_rule_impl(ctx):
    gradle_toolchain = ctx.toolchains["@rules_gradle//:toolchain_type"]
    
    # Get Gradle executable
    gradle_path = (
        gradle_toolchain.gradle_label.path 
        if gradle_toolchain.gradle_label 
        else gradle_toolchain.gradle_path
    )
    
    # Get properties file
    gradle_properties = gradle_toolchain.gradle_properties
    
    # Execute Gradle
    ctx.actions.run_shell(
        command = "{} --gradle-user-home {} build".format(
            gradle_path,
            gradle_properties.dirname if gradle_properties else ""
        ),
        # ...
    )
```

---

## Dependencies

### Required Bazel Modules
- None (standalone module)

### External Tools
- **Gradle**: Version 8.x or compatible
- **Java JDK**: Required by Gradle (provided via Bazel's JDK toolchain)

---

## Platform Support

| Platform | Support Level | Notes |
|----------|--------------|-------|
| Linux (x64) | ✅ Full | Uses label-based toolchain (Gradle as Bazel label) |
| Windows (x64) | ✅ Full | Uses path-based toolchain (system Gradle installation) |
| macOS | ✅ Supported | Same as Linux, requires Gradle installation |

**Platform Differences:**
- **Linux/macOS**: Typically use `gradle_label` (downloaded Gradle)
- **Windows**: Typically use `gradle_path` (installed Gradle)
- .netrc reading works on all platforms

---

## Limitations

1. **Authentication Source**: Only supports .netrc format for credentials
2. **Token Mapping**: Each token requires explicit URL mapping
3. **Password Storage**: Netrc passwords stored in plain text (use file permissions)
4. **Properties Override**: Generated properties take precedence over user's system properties
5. **Local Repository**: Generated properties repository is local=True (not cached)
6. **Security**: gradle.properties contains credentials (keep secure)

---

## Advanced Features

### Multiple Token Sources

Map multiple tokens from different netrc machines:

```python
generate_gradle_properties(
    name = "gradle_properties",
    tokens = {
        "artifactory.user": "artifactory.vector.com",
        "artifactory.password": "artifactory.vector.com",
        "github.token": "github.com",
        "nexus.token": "nexus.internal.com",
    },
)
```

### Base Properties Content

Include standard Gradle configuration:

```python
generate_gradle_properties(
    name = "gradle_properties",
    gradle_properties_content = """
# Performance settings
org.gradle.daemon=false
org.gradle.parallel=true
org.gradle.caching=false
org.gradle.configureondemand=true

# Memory settings
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m

# Network settings
systemProp.http.proxyHost=proxy.example.com
systemProp.http.proxyPort=8080
""",
    tokens = {
        # ... authentication tokens
    },
)
```

### Custom .netrc Location

Specify non-default .netrc file:

```python
generate_gradle_properties(
    name = "gradle_properties",
    netrc = "/path/to/custom/.netrc",
    tokens = {...},
)
```

### Environment Variable .netrc

Use `$NETRC` environment variable:

```bash
export NETRC=/secure/location/.netrc
bazel build //...
```

---

## Security Considerations

1. **Protect .netrc**: Use file permissions (chmod 600)
   ```bash
   chmod 600 ~/.netrc
   ```

2. **Protect Generated Properties**: Keep gradle.properties secure
   - Not committed to version control
   - Generated locally per user
   - Contains authentication credentials

3. **Bazel Output**: Generated repository in bazel-out (not user-writable)

4. **CI/CD**: Inject .netrc securely in CI environment
   ```yaml
   # Example GitHub Actions
   - name: Setup .netrc
     run: |
       echo "machine artifactory.example.com" > ~/.netrc
       echo "  login ${{ secrets.ARTIFACTORY_USER }}" >> ~/.netrc
       echo "  password ${{ secrets.ARTIFACTORY_TOKEN }}" >> ~/.netrc
       chmod 600 ~/.netrc
   ```

---

## Troubleshooting

### Common Issues

**Issue**: "Gradle toolchain is needed for DaVinci Team"
- **Solution**: Ensure gradle toolchain is defined and registered
- **Check**: At least one of `gradle_label` or `gradle_path` must be set

**Issue**: "No authentication token found in .netrc"
- **Solution**: Verify .netrc contains matching machine entry
- **Check**: URL in `tokens` dict matches .netrc machine exactly

**Issue**: Generated properties file not found
- **Solution**: Ensure repository name is correct: `@<name>//:gradle.properties`
- **Check**: Run `bazel query @gradle_properties//...` to verify

**Issue**: Gradle execution fails with "permission denied"
- **Solution**: Ensure Gradle executable has execute permissions
- **Linux**: `chmod +x gradle`

**Issue**: Authentication fails in Gradle build
- **Solution**: Verify generated properties contains correct tokens
- **Debug**: Check `bazel-out/.../external/gradle_properties/gradle.properties`

**Issue**: .netrc not found
- **Solution**: Create .netrc in home directory or set `$NETRC` variable
- **Location**: `~/.netrc` (Linux/macOS) or `%HOME%/_netrc` (Windows)
