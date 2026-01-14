#!/bin/bash
set -e

ZIP_EXE=$1
ZIP_FILE=$2
OUTPUT_DIR=$3

if [ -z "$ZIP_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: $0 <zip-file> <output-dir>"
  exit 1
fi

$ZIP_EXE -o "$ZIP_FILE" -d "$BUILD_WORKING_DIRECTORY/$OUTPUT_DIR"