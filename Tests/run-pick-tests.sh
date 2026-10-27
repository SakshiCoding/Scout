#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-pick-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
SCOUT_PICK_FIXTURE="$test_dir/snapshot.json" npm test --prefix Tests/database
xcrun swiftc -parse-as-library Scout/Models/Restaurant.swift \
  Scout/Models/SharedPickSession.swift Tests/PickSessionTests.swift -o "$test_dir/pick-tests"
"$test_dir/pick-tests" "$test_dir/snapshot.json"
