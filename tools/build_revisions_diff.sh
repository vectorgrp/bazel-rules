#!/bin/bash

set -e

# Path to your Bazel WORKSPACE directory
workspace_path=$PWD
# Starting Revision SHA
previous_revision=$1
# Final Revision SHA
final_revision=$2

starting_hashes_json="/tmp/starting_hashes.json"
final_hashes_json="/tmp/final_hashes.json"
impacted_targets_path="/tmp/impacted_targets.txt"
bazel_diff="/tmp/bazel_diff"

bazel run :bazel-diff --script_path="$bazel_diff"

git -C "$workspace_path" checkout "$previous_revision" --quiet

echo "Generating Hashes for Revision '$previous_revision'"
$bazel_diff generate-hashes -w "$workspace_path" $starting_hashes_json --excludeExternalTargets

git -C "$workspace_path" checkout "$final_revision" --quiet

echo "Generating Hashes for Revision '$final_revision'"
$bazel_diff generate-hashes -w "$workspace_path" $final_hashes_json --excludeExternalTargets

echo "Determining Impacted Targets"
$bazel_diff get-impacted-targets -sh $starting_hashes_json -fh $final_hashes_json -o $impacted_targets_path

impacted_targets=()
IFS=$'\n' read -d '' -r -a impacted_targets < $impacted_targets_path || true
formatted_impacted_targets=$(IFS=$'\n'; echo "${impacted_targets[*]}")
echo "Impacted Targets between $previous_revision and $final_revision:"
echo "$formatted_impacted_targets" | xargs bazel build
