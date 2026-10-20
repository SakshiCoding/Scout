#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-widget-render.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
  Scout/Models/Restaurant.swift \
  Scout/Models/ScoutWidgetSnapshot.swift \
  Scout/Theme/AtlasTheme.swift \
  ScoutWidgetExtension/ScoutWidgetView.swift \
  Tests/WidgetRenderTests.swift \
  -o "$test_dir/render-widget"
"$test_dir/render-widget" "${1:-/tmp/scout-widget-previews}"
