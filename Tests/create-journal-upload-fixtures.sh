#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:?Pass a new directory for synthetic media fixtures}"
[[ ! -e "$output" ]] || { echo 'Use a new directory; existing files are not overwritten.' >&2; exit 1; }
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-fixture-generator.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library Tests/create-journal-upload-fixtures.swift -o "$test_dir/create-fixtures"
"$test_dir/create-fixtures" "$output"
