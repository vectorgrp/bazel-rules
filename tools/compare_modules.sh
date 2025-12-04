#!/bin/bash

folder1=$1
folder2=$2

# Function to compare folder names
compare_folders() {
  local dir1=$1
  local dir2=$2

  for subdir1 in "$dir1"/*; do
    if [ -d "$subdir1" ]; then
      subdir_name=$(basename "$subdir1")
      subdir2="$dir2/$subdir_name"
      if [ ! -d "$subdir2" ]; then
        if [ "$subdir_name" == "srcs" ]; then
          echo "Skipping missing folder 'srcs' in $dir2"
          continue
        else
          echo "Error: Folder $subdir_name does not match in $dir2"
          exit 1
        fi
      fi
      # Recursively compare subdirectories
      compare_folders "$subdir1" "$subdir2"
    fi
  done
}

compare_folders "$folder1" "$folder2"
