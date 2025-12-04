"""Helper rule to build a source.json file for modules"""

# TODO: maybe add sha256 and base64 as deps???
_CALC_SHA256_CMD = """
set -euo pipefail
# Calculate SHA-256 hash
sha256_hash=$(sha256sum "{archive_path}" | cut -d ' ' -f 1)
base64_hash=sha256-$(echo -n "$sha256_hash" | xxd -r -p | base64)
"""

_SET_SHA256_CMD = """
set -euo pipefail
# Set SHA-256 hash to avoid having to download the archive each time if the value is already known
base64_hash={integrity}
"""

_SOURCE_JSON_CMD = """
cat <<EOL > {output_file}
{{
    "url": "{url}",
    "integrity": "$base64_hash"
EOL

# Conditionally add the strip_prefix line
if [ -n "{strip_prefix}" ]; then
    sed -i '$ s/$/,/' {output_file}
    echo '    "strip_prefix": "{strip_prefix}"' >> {output_file}
fi

# Close the JSON object
cat <<EOL >> {output_file}
}}
"""

def _source_json_impl(ctx):
    source_json_file = ctx.actions.declare_file("source.json")
    SOURCE_JSON_CMD = _SOURCE_JSON_CMD.format(output_file = source_json_file.path, url = ctx.attr.archive_url, strip_prefix = ctx.attr.strip_prefix)

    if ctx.attr.integrity == "" and ctx.file.module_archive == None:
        fail("Either integrity or a valid module archive has to be provided!")

    if ctx.attr.integrity != "" and ctx.file.module_archive == None:
        SET_SHA256_CMD = _SET_SHA256_CMD.format(integrity = ctx.attr.integrity)
        ctx.actions.run_shell(
            outputs = [source_json_file],
            command = SET_SHA256_CMD + SOURCE_JSON_CMD,
        )
    else:
        CALC_SHA256_CMD = _CALC_SHA256_CMD.format(archive_path = ctx.file.module_archive.path)
        ctx.actions.run_shell(
            inputs = [ctx.file.module_archive],
            outputs = [source_json_file],
            command = CALC_SHA256_CMD + SOURCE_JSON_CMD,
        )

    return [DefaultInfo(files = depset([source_json_file]))]

source_json = rule(
    implementation = _source_json_impl,
    attrs = {
        "strip_prefix": attr.string(doc = "Strip the prefix of the downloaded archive", mandatory = False, default = ""),
        "archive_url": attr.string(doc = "The base url of the registry where the module archive will be uploaded to", mandatory = True, default = ""),
        "module_archive": attr.label(doc = "The archive to build the module from", allow_single_file = True, mandatory = False, default = None),
        "integrity": attr.string(doc = "Alternative to using the actual archive to calculate the sha, one can be provided, to avoid adding an expensive dependency to this target", default = "", mandatory = False),
    },
)
