$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

try {{

    # List of files to ignore
    $ignoreList = @({excluded_files})

    # List of components
    $components = @({components_list})

    # Function to check if a file is in the ignore list
    function ShouldIgnore {{
        param (
            [string]$fileName
        )
        return $ignoreList -contains $fileName
    }}

    # Function to determine which component a file belongs to
    function GetFileComponent {{
        param (
            [string]$filePath
        )

        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

        foreach ($component in $components) {{
            # Check if filename starts with component name (e.g., Com_*, BswM_*, etc.)
            if ($fileName -like "${{component}}_*" -or $fileName -eq $component) {{
                return $component
            }}
        }}

        return "main"  # Default to main if no component match
    }}

    # Create all destination folders
    $allDirs = @("{sources_dir}", "{headers_dir}"{component_dirs_list})
    foreach ($dir in $allDirs) {{
        if (-not (Test-Path -Path $dir)) {{
            New-Item -ItemType Directory -Path $dir -Force
        }}
    }}

    # Process .h files. Ignore all files from the RteAnalyzer folder
    Get-ChildItem -Path {generator_output_dir} -Filter *.h -Recurse | Where-Object {{ $_.FullName -notlike "*RteAnalyzer*" }} | ForEach-Object {{
        #if (-not (ShouldIgnore -fileName $_.Name)) {{
            # Always copy to main headers directory first
            Copy-Item -Path $_.FullName -Destination {headers_dir}
        #}}
    }}

    # Define the list of file patterns to include
    $sourceFilePatterns = @("*.c", "*.asm", "*.inc", "*.inl", "*.S", "*.s", "*.a")

    if ({additional_source_file_endings} -and {additional_source_file_endings} -ne @("")) {{
        $sourceFilePatterns += {additional_source_file_endings}
    }}

    # Process source files. Ignore all files from the RteAnalyzer folder
    foreach ($pattern in $sourceFilePatterns) {{
        Get-ChildItem -Path {generator_output_dir} -Filter $pattern -Recurse | Where-Object {{ $_.FullName -notlike "*RteAnalyzer*" }} | ForEach-Object {{
            if (-not (ShouldIgnore -fileName $_.Name)) {{
                # Always copy to main sources directory first
                Copy-Item -Path $_.FullName -Destination {sources_dir}
            }}
        }}
    }}

    # Move component-specific files from main directories to component directories
    # Process headers first
    Get-ChildItem -Path {headers_dir} -Filter *.h | ForEach-Object {{
        $component = GetFileComponent -filePath $_.FullName

        # If this file belongs to a specific component, move it to component directory
        if ($component -ne "main") {{
            $componentHeadersDir = "{headers_dir}/../generated_headers_${{component}}"
            if (Test-Path $componentHeadersDir) {{
                Move-Item -Path $_.FullName -Destination $componentHeadersDir
            }}
        }}
    }}

    # Process sources
    foreach ($pattern in $sourceFilePatterns) {{
        Get-ChildItem -Path {sources_dir} -Filter $pattern | ForEach-Object {{
            $component = GetFileComponent -filePath $_.FullName

            # If this file belongs to a specific component, move it to component directory
            if ($component -ne "main") {{
                $componentSourcesDir = "{sources_dir}/../generated_sources_${{component}}"
                if (Test-Path $componentSourcesDir) {{
                    Move-Item -Path $_.FullName -Destination $componentSourcesDir
                }}
            }}
        }}
    }}

    Write-Output "Files have been moved successfully."
}} catch {{
    Write-Error "An error occurred: $_"
    exit 1
}}
