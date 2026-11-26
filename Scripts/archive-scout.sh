#!/bin/bash
# Archive all three production targets with one explicit, unused App Store build number.
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
build_number="${1:?Usage: Scripts/archive-scout.sh BUILD_NUMBER [--unsigned]}"
[[ "$build_number" =~ ^[1-9][0-9]{0,3}$ ]] || { echo 'Choose an unused build number from 1 through 9999.' >&2; exit 1; }
mode="${2:-signed}"
[[ "$mode" == signed || "$mode" == --unsigned ]] || { echo 'Only --unsigned is supported as a second argument.' >&2; exit 1; }
archive="${SCOUT_ARCHIVE_PATH:-/tmp/scout-release/$build_number/Scout.xcarchive}"
[[ ! -e "$archive" ]] || { echo 'Archive already exists; choose a new output path.' >&2; exit 1; }
mkdir -p "$(dirname "$archive")"
log="$(dirname "$archive")/archive.log"
args=(-project Scout.xcodeproj -scheme Scout -configuration Release -destination 'generic/platform=iOS'
      -archivePath "$archive" "CURRENT_PROJECT_VERSION=$build_number")
if [[ "$mode" == --unsigned ]]; then
  args+=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO)
else
  args+=(-allowProvisioningUpdates)
fi
if ! xcodebuild "${args[@]}" archive >"$log" 2>&1; then
  echo "Archive failed. Inspect the private log: $log" >&2
  exit 1
fi
python3 Scripts/validate-scout-archive.py "$archive" "$build_number" "$mode"
echo "Archive: $archive"
