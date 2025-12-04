"""Simple helper rule to create a metadata.json file for a number of module versions"""

_METADATA_CMD = """
set -euo pipefail

cat <<EOF > {metadata_json_path}
{{
    "homepage": "{homepage}",
    "maintainers": [{maintainers}],
    "repository": [{repository}],
    "versions": [{versions}],
    "yanked_versions": {yanked_versions}
}}
EOF
"""

def _list_to_json(input_list):
    if len(input_list) < 1:
        return ""

    # Dont want to run a formating tool here and want the file to look readable
    return '\n        "' + '",\n        "'.join(input_list) + '"\n    '

def _dict_to_json(input_dict):
    if len(input_dict.items()) < 1:
        return "{ }"
    input_list = [item[0] + "\": \"" + item[1] for item in input_dict.items()]
    return '{\n        "' + '",\n        "'.join(input_list) + '"\n    }'

def _metadata_json_impl(ctx):
    metadata_json_file = ctx.actions.declare_file(ctx.label.name + "/metadata.json")

    ctx.actions.run_shell(
        outputs = [metadata_json_file],
        command = _METADATA_CMD.format(
            metadata_json_path = metadata_json_file.path,
            versions = _list_to_json(ctx.attr.versions),
            repository = _list_to_json(ctx.attr.repository),
            maintainers = _list_to_json(ctx.attr.maintainers),
            homepage = ctx.attr.homepage,
            yanked_versions = _dict_to_json(ctx.attr.yanked_versions),
        ),
    )
    return DefaultInfo(
        files = depset([metadata_json_file]),
    )

metadata_json = rule(
    implementation = _metadata_json_impl,
    attrs = {
        "maintainers": attr.string_list(doc = "The list of maintainers for this module", mandatory = False, default = []),
        "homepage": attr.string(doc = "The homepage of this model", mandatory = False, default = ""),
        "repository": attr.string_list(doc = "List of repositories of the module", mandatory = False, default = []),
        "yanked_versions": attr.string_dict(doc = "List of yanked versions that are no longer supported", mandatory = False, default = {}),
        "versions": attr.string_list(mandatory = True, doc = "The list of module versions that this metadata_json should contain", allow_empty = False, default = []),
    },
)
