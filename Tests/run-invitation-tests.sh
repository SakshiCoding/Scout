#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-invite-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
SCOUT_INVITE_FIXTURE="$test_dir/fixture.json" node Tests/database/circle-invitations.test.mjs
xcrun swiftc -parse-as-library Scout/Models/Circle.swift Scout/Theme/AtlasTheme.swift \
  Scout/Models/CircleInvitation.swift Tests/CircleInvitationTests.swift -o "$test_dir/invite-tests"
"$test_dir/invite-tests" "$test_dir/fixture.json"
