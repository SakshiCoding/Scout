#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-upload-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library Scout/Models/Media.swift Scout/Services/ScoutMediaUploadPolicy.swift Scout/Services/JournalMediaFile.swift \
    Tests/MediaUploadPolicyTests.swift -o "$test_dir/upload-tests"
"$test_dir/upload-tests"
node Tests/database/journal-upload-bucket.test.mjs
