#!/bin/bash

# MIT License

# Copyright (c) 2025 Vector Group

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

set -e -o pipefail

# Filter generated files to include only needed files
mkdir -p "{headers_dir}"


mkdir -p "{sources_dir}"


# Create component-specific directories
{component_dirs_creation}

# Function to determine component from filename
get_component() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    local base_name="${filename%.*}"

    # List of components
    components=({components_list})

    # First, check for exact match (files named exactly like the component)
    for component in "${components[@]}"; do
        if [[ "$base_name" == "$component" ]]; then
            echo "$component"
            return
        fi
    done

    # Second, check for prefix match with underscore (e.g., Com_PduR)
    # Sort by length (longest first) to avoid shorter names matching prefixes of longer names
    for component in "${components[@]}"; do
        if [[ "$base_name" == "${component}_"* ]]; then
            echo "$component"
            return
        fi
    done

    echo "main"
}

# Filter and copy header files
{rsync_exe} --log-file="{rsync_log_file_hdrs}" --verbose --prune-empty-dirs --archive --itemize-changes --quiet --filter "+ */"  {excluded_files_patterns} --filter "+ **/*.h" --filter "- *"   {generator_output_dir} {headers_dir}
chmod 777 "{headers_dir}" -R
# Filter and copy source files
{rsync_exe} --log-file="{rsync_log_file_srcs}" --verbose --prune-empty-dirs --archive --itemize-changes --quiet --filter "+ */"  {excluded_files_patterns} --filter "+ **/*.c" --filter "+ **/*.asm" --filter "+ **/*.inc" --filter "+ **/*.inl" --filter "+ **/*.S" --filter "+ **/*.s" --filter "+ **/*.a"  {additional_source_file_endings} --filter "- *"   {generator_output_dir} {sources_dir}
chmod 777 "{sources_dir}" -R
# Move component-specific files from main directories to component directories
# Process headers first
find {headers_dir} -name "*.h"  | while read -r file; do
    component=$(get_component "$file")

    # If this file belongs to a specific component, move it to component directory
    if [ "$component" != "main" ]; then
        component_headers_dir="{headers_dir}/../generated_headers_$component"
        if [ -d "$component_headers_dir" ]; then
            mv "$file" "$component_headers_dir/"
        fi
    fi
done
# Process sources
find {sources_dir} -name "*.*" | while read -r file; do
    component=$(get_component "$file")

    # If this file belongs to a specific component, move it to component directory
    if [ "$component" != "main" ]; then
        component_sources_dir="{sources_dir}/../generated_sources_$component"
        if [ -d "$component_sources_dir" ]; then
            mv "$file" "$component_sources_dir/"
        fi
    fi
done