#!/bin/bash
# Export a signed archive, or send it to App Store Connect after validation.
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
archive="${1:?Usage: Scripts/export-scout.sh /path/Scout.xcarchive [--upload]}"
mode="${2:-export}"
[[ "$mode" == export || "$mode" == --upload ]] || { echo 'Only --upload is supported as a second argument.' >&2; exit 1; }
[[ -f "$archive/Products/Applications/Scout.app/embedded.mobileprovision" ]] || { echo 'A signed device archive is required; unsigned QA archives cannot be distributed.' >&2; exit 1; }
output="${SCOUT_EXPORT_PATH:-$(dirname "$archive")/AppStore}"
[[ ! -e "$output" ]] || { echo 'Export path already exists; choose a new output path.' >&2; exit 1; }
mkdir -p "$output"
python3 - "$output/ExportOptions.plist" "$mode" <<'PY'
import plistlib,sys
with open(sys.argv[1],'wb') as f:
    plistlib.dump({'method':'app-store-connect','destination':'upload' if sys.argv[2]=='--upload' else 'export',
                  'signingStyle':'automatic','manageAppVersionAndBuildNumber':False,
                  'uploadSymbols':True},f)
PY
if ! xcodebuild -exportArchive -archivePath "$archive" -exportPath "$output" \
    -exportOptionsPlist "$output/ExportOptions.plist" -allowProvisioningUpdates >"$output/export.log" 2>&1; then
  echo "Export/upload failed. Inspect the private log: $output/export.log" >&2
  exit 1
fi
if [[ "$mode" == --upload ]]; then
  echo 'Upload command succeeded. Confirm processing and tester availability in App Store Connect → TestFlight.'
else
  echo "Exported for App Store Connect: $output"
fi
