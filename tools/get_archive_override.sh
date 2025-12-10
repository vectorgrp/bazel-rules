#!/bin/bash

set -euo pipefail

# shell variables
upload_url=$1
archive_path=$2

# Copy archive_override to clipboard

folder_name=$(basename "$archive_path" .zip)

sha256_hash=$(sha256sum "$archive_path" | cut -d ' ' -f 1)

base64_hash=$(echo -n "$sha256_hash" | xxd -r -p | base64)

text="archive_override(
    module_name = \"${folder_name}\",
    integrity = \"sha256-${base64_hash}\",
    url = \"${upload_url}\",
)"

echo "Use following in your MODULE.bazel to override module with current version"
echo "--------------------------------------------------------------------------"
echo "$text"
echo "--------------------------------------------------------------------------"

if echo "$text" | clip.exe >/dev/null 2>&1; then
    echo "You can simply use Strg+V to paste the override module."
fi
