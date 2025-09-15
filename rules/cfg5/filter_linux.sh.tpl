#!/bin/bash
set -e -o pipefail

# Filter generated files to include only needed files
mkdir -p "{headers_dir}"
mkdir -p "{sources_dir}"

# Create component-specific directories
{component_dirs_creation}

# Function to determine component from filename
get_component() {{
    local file_path="$1"
    local filename=$(basename "$file_path")
    local base_name=$(basename "$filename" | sed 's/\\.[^.]*$//')

    # List of components
    components=({components_list})

    for component in "${{components[@]}}"; do
        if [[ "$base_name" == "${{component}}_"* ]] || [[ "$base_name" == "$component" ]]; then
            echo "$component"
            return
        fi
    done

    echo "main"
}}

# Filter and copy header files. Ignore all files from the RteAnalyzer folder
{rsync_exe} --log-file="{rsync_log_file_hdrs}" --verbose --prune-empty-dirs --archive --itemize-changes --quiet --filter "+ */" --filter "- **/RteAnalyzer/**" {excluded_files_patterns} --filter "+ **/*.h" --filter "- *"   {generator_output_dir} {headers_dir}

# Filter and copy source files. Ignore all files from the RteAnalyzer folder
{rsync_exe} --log-file="{rsync_log_file_srcs}" --verbose --prune-empty-dirs --archive --itemize-changes --quiet --filter "+ */" --filter "- **/RteAnalyzer/**" {excluded_files_patterns} --filter "+ **/*.c" --filter "+ **/*.asm" --filter "+ **/*.inc" --filter "+ **/*.inl" --filter "+ **/*.S" --filter "+ **/*.s" --filter "+ **/*.a"  {additional_source_file_endings} --filter "- *"   {generator_output_dir} {sources_dir}

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
