#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
simulator_id="${1:?Pass the UUID of a fresh booted Scout Hours QA simulator}"
derived_dir="${2:-/tmp/scout-derived}"
source_app="$derived_dir/Build/Products/Debug-iphonesimulator/Scout.app"
# The real bundle ID is needed for an iOS-restricted key; never replace an existing install.
xcrun simctl list devices --json | python3 -c 'import json,sys; d=[x for a in json.load(sys.stdin)["devices"].values() for x in a if x["udid"]==sys.argv[1]]; assert len(d)==1 and d[0]["state"]=="Booted" and d[0]["name"].startswith("Scout Hours QA"), "Use a fresh, booted Scout Hours QA simulator"' "$simulator_id"
xcrun simctl bootstatus "$simulator_id" -b >/dev/null
if xcrun simctl get_app_container "$simulator_id" com.sakshisangani.Scout data >/dev/null 2>&1; then
  echo 'Refusing to replace an installed Scout app; use a fresh disposable simulator.' >&2
  exit 1
fi
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/scout-live-hours.XXXXXX")
installed=0
cleanup() {
  if [[ "$installed" == 1 ]]; then
    xcrun simctl terminate "$simulator_id" com.sakshisangani.Scout >/dev/null 2>&1 || true
    xcrun simctl uninstall "$simulator_id" com.sakshisangani.Scout >/dev/null 2>&1 || true
  fi
  rm -rf "$test_dir"
}
trap cleanup EXIT
mkdir "$test_dir/Scout.app"
python3 - "$source_app" "$test_dir/Scout.app" <<'PY'
import pathlib,plistlib,shutil,sys
source,target=map(pathlib.Path,sys.argv[1:])
key=plistlib.loads((source/'Info.plist').read_bytes())['GOOGLE_MAPS_API_KEY']
assert key.startswith('AIza') and len(key)==39, 'Build Scout with a configured local Maps key first'
info={'CFBundleIdentifier':'com.sakshisangani.Scout','CFBundleExecutable':'Scout','CFBundleName':'Scout Hours QA','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':'1.0','LSRequiresIPhoneOS':True,'UILaunchScreen':{},'GOOGLE_MAPS_API_KEY':key}
(target/'Info.plist').write_bytes(plistlib.dumps(info))
shutil.copytree(source/'GooglePlaces_GooglePlacesTarget.bundle',target/'GooglePlaces_GooglePlacesTarget.bundle')
shutil.copytree(source/'GooglePlaces_GooglePlacesTarget.bundle/GooglePlaces.bundle',target/'GooglePlaces.bundle')
PY
simulator_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
simulator_arch=$(uname -m)
xcrun --sdk iphonesimulator swiftc -parse-as-library -sdk "$simulator_sdk" -target "$simulator_arch-apple-ios17.6-simulator" \
  -I "$derived_dir/SourcePackages/artifacts/ios-places-sdk/GooglePlaces/GooglePlaces.xcframework/ios-arm64_x86_64-simulator/Headers" \
  "$derived_dir/Build/Products/Debug-iphonesimulator/GooglePlaces.a" \
  -lc++ -lz -framework CoreGraphics -framework CoreLocation -framework CoreText -framework QuartzCore -framework Security -framework UIKit -Xlinker -ObjC \
  Scout/Models/Restaurant.swift Scout/Models/PlacePhoto.swift Scout/Services/PlacePhotoLoadState.swift Scout/Views/Detail/PlacePhotoCredits.swift Scout/Models/PlaceContactDetails.swift Scout/Services/RestaurantEnrichment.swift \
  Scout/Services/PlacesService.swift Scout/Services/PlaceDetailsLoadState.swift Scout/Theme/AtlasTheme.swift \
  Scout/Views/Detail/RestaurantHoursCard.swift Tests/LivePlaceHoursCheck.swift -o "$test_dir/Scout.app/Scout"
codesign --force --sign - "$test_dir/Scout.app" >/dev/null 2>&1
xcrun simctl install "$simulator_id" "$test_dir/Scout.app"
installed=1
xcrun simctl launch "$simulator_id" com.sakshisangani.Scout >/dev/null
container=$(xcrun simctl get_app_container "$simulator_id" com.sakshisangani.Scout data)
for _ in {1..45}; do
  if [[ -f "$container/Documents/hours-report.json" ]]; then break; fi
  sleep 1
done
python3 - "$container/Documents/hours-report.json" <<'PY'
import json,pathlib,sys
p=pathlib.Path(sys.argv[1])
assert p.exists(), 'Live hours check produced no report within 45 seconds'
r=json.loads(p.read_text())
print(json.dumps(r,ensure_ascii=True))
assert r.get('passed'), 'Live Google Places verification failed; see sanitized report above'
PY

if [[ -n "${SCOUT_LIVE_SCREENSHOT:-}" ]]; then
  xcrun simctl io "$simulator_id" screenshot "$SCOUT_LIVE_SCREENSHOT" >/dev/null
fi
