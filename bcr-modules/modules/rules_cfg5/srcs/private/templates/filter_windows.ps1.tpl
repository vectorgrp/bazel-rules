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

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

try {

    # List of files to ignore
    $ignoreList = @({excluded_files})

    # List of components
    $components = @({components_list})

    # precompile exclude patterns
    $ignorePatterns = foreach ($pattern in $ignoreList) {
        # convert '/' to platform specific separator
        $p = $pattern -replace '/', [IO.Path]::DirectorySeparatorChar
        $p
    }
    
    # Function to check if a file is in the ignore list or matches an ignore pattern
    function ShouldIgnore {
        param (
            [Parameter(Mandatory)]
            [System.IO.FileSystemInfo]$Item
        )

        $fileName = $Item.Name
        $filePath = $Item.FullName

        foreach ($pattern in $ignorePatterns) {
            if ($filePath -like $pattern) {
                return $true
            }
            if ($fileName -like $pattern) {
                return $true
            }
        }

        return $false
    }

    # Function to determine which component a file belongs to
    function GetFileComponent {
        param (
            [string]$filePath
        )

        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

        # First, check for exact match (files named exactly like the component)
        foreach ($component in $components) {
            if ($fileName -eq $component) {
                return $component
            }
        }

        # Second, check for prefix match with underscore (e.g., Com_PduR)
        foreach ($component in $components) {
            if ($fileName -like "${component}_*") {
                return $component
            }
        }

        return "main"  # Default to main if no component match
    }

    # Create all destination folders
    $allDirs = @("{sources_dir}", "{headers_dir}"{component_dirs_list})
    foreach ($dir in $allDirs) {
        if (-not (Test-Path -Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force
        }
    }

    # Process .h files
    Get-ChildItem -Path {generator_output_dir} -Filter *.h -Recurse | ForEach-Object {
        if (-not (ShouldIgnore -Item $_)) {
            $destFile = Join-Path {headers_dir} $_.Name
            if (Test-Path $destFile) {
                Write-Warning "Duplicated generated file file '$($_.FullName)'. Destination file '$destFile' file already exists."
            } else {
                Copy-Item -Path $_.FullName -Destination {headers_dir}
            }
        }
    }

    # Define the list of file patterns to include
    $sourceFilePatterns = @("*.c", "*.asm", "*.inc", "*.inl", "*.S", "*.s", "*.a")

    if ({additional_source_file_endings} -and {additional_source_file_endings} -ne @("")) {
        $sourceFilePatterns += {additional_source_file_endings}
    }

    # Process source files
    foreach ($pattern in $sourceFilePatterns) {
        Get-ChildItem -Path {generator_output_dir} -Filter $pattern -Recurse | ForEach-Object {
            if (-not (ShouldIgnore -Item $_)) {
                $destFile = Join-Path {sources_dir} $_.Name
                if (Test-Path $destFile) {
                    Write-Warning "Duplicated generated file file '$($_.FullName)'. Destination file '$destFile' file already exists."
                } else {
                    # Always copy to main sources directory first
                    Copy-Item -Path $_.FullName -Destination {sources_dir}
                }
            }
        }
    }

    # Move component-specific files from main directories to component directories
    # Process headers first
    Get-ChildItem -Path {headers_dir} -Filter *.h | ForEach-Object {
        $component = GetFileComponent -filePath $_.FullName

        # If this file belongs to a specific component, move it to component directory
        if ($component -ne "main") {
            $componentHeadersDir = "{headers_dir}/../generated_headers_${component}"
            if (Test-Path $componentHeadersDir) {
                Move-Item -Path $_.FullName -Destination $componentHeadersDir
            }
        }
    }

    # Process sources
    foreach ($pattern in $sourceFilePatterns) {
        Get-ChildItem -Path {sources_dir} -Filter $pattern | ForEach-Object {
            $component = GetFileComponent -filePath $_.FullName

            # If this file belongs to a specific component, move it to component directory
            if ($component -ne "main") {
                $componentSourcesDir = "{sources_dir}/../generated_sources_${component}"
                if (Test-Path $componentSourcesDir) {
                    Move-Item -Path $_.FullName -Destination $componentSourcesDir
                }
            }
        }
    }

    Write-Output "Files have been moved successfully."
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}