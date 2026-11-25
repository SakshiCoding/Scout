"""Inspect real packaged targets; never print local API configuration values."""
import pathlib, plistlib, subprocess, sys
archive = pathlib.Path(sys.argv[1])
expected_build = sys.argv[2]
unsigned = sys.argv[3] == '--unsigned'
app = archive / 'Products/Applications/Scout.app'
targets = [(app, 'com.sakshisangani.Scout'),
           (app / 'PlugIns/ScoutShareExtension.appex', 'com.sakshisangani.Scout.ShareExtension'),
           (app / 'PlugIns/ScoutWidgetExtension.appex', 'com.sakshisangani.Scout.WidgetExtension')]
version = None
for target, identifier in targets:
    info = plistlib.loads((target / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == identifier, f'Wrong bundle identifier: {target.name}'
    assert info['CFBundleVersion'] == expected_build, f'Build mismatch: {target.name}'
    version = version or info['CFBundleShortVersionString']
    assert info['CFBundleShortVersionString'] == version, f'Version mismatch: {target.name}'
    assert info['MinimumOSVersion'] == '17.6', f'Unexpected deployment target: {target.name}'
    if not unsigned:
        assert (target / 'embedded.mobileprovision').is_file(), f'Missing provisioning profile: {target.name}'
        subprocess.run(['codesign', '--verify', '--strict', str(target)], check=True)
info = plistlib.loads((app / 'Info.plist').read_bytes())
for key in ['GOOGLE_MAPS_API_KEY', 'GEMINI_API_KEY', 'GEMINI_MODEL']:
    value = info.get(key, '')
    assert value and not value.startswith('$('), f'Missing local release setting: {key}'
assert (app / 'Assets.car').is_file(), 'Missing compiled app assets'
assert (app / 'Metadata.appintents/extract.actionsdata').is_file(), 'Missing App Intents metadata'
label = 'UNSIGNED device compile/package verification; cannot install or upload' if unsigned else 'Signed archive structure verified; App Store validation still required'
print(f'PASS {label}: version {version}, build {expected_build}, main app + Share + Widget')
