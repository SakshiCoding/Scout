# Scout MVP beta release

Scout is the circles-based restaurant wishlist, map, shared picker, and photo/video journal. The recipe/cooking idea remains deferred.

## Prepare the release

1. In Xcode → Settings → Accounts, add an Apple Developer account with access to paid team `345D62AZC4`. Do not send passwords or signing keys in chat. If Scout should use another team, confirm it before changing project settings.
2. In Apple Developer, verify Sign in with Apple for `com.sakshisangani.Scout` and App Group `group.com.sakshisangani.Scout` on the main app, `.ShareExtension`, and `.WidgetExtension`. All three targets need provisioning. Keep their existing identifiers.
3. In App Store Connect, confirm an iOS app record for the main bundle identifier, agreements, beta description, contact/review details, privacy information, and export-compliance answers. External testers may require Beta App Review; internal testers need App Store Connect access. Never invite people automatically.
4. Fill ignored `Scout/Config.xcconfig` from its example. Confirm production Supabase availability, Apple Auth configuration, Maps SDK/Places API access for the real bundle ID, and Gemini access. Keep local config, logs, archives and IPA files out of git. Release archives include the configured client API values.
5. Apply all repository migrations to the existing Scout project. `enable_journal_video_uploads` preserves the private bucket and its membership policies while accepting JPEG/PNG/HEIC/HEIF and MP4/MOV/M4V with a 50 MiB bucket ceiling. Client photos are limited to 10 MiB, videos to 50 MiB, and each entry to 100 MiB total.
6. Select a build number unused in App Store Connect. Run from the repository root:

```sh
Scripts/archive-scout.sh 2
Scripts/export-scout.sh /tmp/scout-release/2/Scout.xcarchive --upload
```

The archive script uses Release for a generic physical iOS device, overrides the build number for all three targets, and checks packaged identifiers, versions, local configuration and extensions. Logs are private. The export script refuses an unsigned archive, uses `app-store-connect`, preserves the tested build number, and requests automatic signing. Set `SCOUT_ARCHIVE_PATH` / `SCOUT_EXPORT_PATH` to unused destinations if needed. Omitting `--upload` exports locally.

`Scripts/archive-scout.sh 2 --unsigned` verifies device compilation and packaging without an Apple account. **It cannot produce an installable or TestFlight build.** Signed export/App Store validation and successful processing are still required. Do not overwrite a previous archive or report an upload from a successful unsigned build.

After upload, confirm the version/build under App Store Connect → TestFlight has finished processing. Resolve any signing, entitlement, privacy or compliance validation failures. Make it available to the intended tester group and copy its approved TestFlight link for the users. Upload success alone does not mean testers can install it.

## Two-iPhone acceptance check

Use separate real accounts on two phones. Save non-sensitive test content and delete it afterward.

- Install the same TestFlight build on both phones; sign in with Apple, restart, and verify sessions/circles restore. Also exercise email sign-in and password recovery if offered.
- Phone A creates a circle and an invitation. Phone B opens it while signed out, signs in, previews, confirms, and sees the same members/wishlist. Replaced and revoked invitations must stop future joins.
- Add a restaurant manually and through Google Places. Both phones see it after refresh. Check real map pins, location permission denial/approval, hours/status timestamps, contact links, and photo credits. A place without a Google ID keeps the neutral photo fallback.
- On Home, search for saved/visited and new restaurants. Saved entries should open details; new results should open the complete prefilled Add form. Cancel without saving, then retry and explicitly Save; confirm the new place appears on both phones. Repeat with location permission denied and inspect the compact photo credits.
- Use Pick on both phones: different votes, unanimous match, undo before matching, rematch, reopen, and brief network loss/recovery. Neither phone may manufacture the other member's vote.
- Share a Safari/Apple Maps/Google Maps link into Scout. Review and save. Try a TikTok/Instagram link with available caption text; an uncertain parse must remain editable.
- Mark a place visited; save a rating, note, photo, and short MOV/MP4 video. Reopen on both phones. Play/share the video, swipe photos, add a second entry, delete media, and move an accidentally visited restaurant back to the wishlist.
- Confirm journal photos take priority over Google photos. Delete the selected cover and confirm fallback/retry. Change circles and sign out while images load; previous-circle photos must disappear.
- Try an oversized video, an unreadable file, and enough media to reach the entry limit. Show an actionable error without silently adding invalid attachments. Cancel a picker selection and retry.
- Switch to an unrelated circle/account and confirm private media is inaccessible. Check widget content and Shortcuts after circle changes and sign-out. Test camera and denied permissions on real hardware.

Record device/OS, build number, each failure, and steps to reproduce before promoting the beta beyond these two testers.

## Verification record — November 25, 2026

- Live Google SDK check passed: public restaurant search, seven hours rows, checked open status/contact, 1024×680 photo and one author attribution.
- Unsigned iOS Release archive passed for app, Share Extension, and widget, version 1.0 build 2. This verifies compilation/package structure only.
- Signed archive attempt failed because Xcode has no account/profiles for the configured team. No TestFlight upload or physical-device acceptance is claimed.
- All seven hosted formats passed byte-identical round trips and access-denial checks; unsupported and oversized uploads were rejected. Native iOS codec/playability tests passed. Disposable fixtures were removed and security advisories matched baseline.
- Home discovery/layout checks also passed: saved/new routing, cancellation and circle isolation, 320pt/accessibility row renders, real location-free Google discovery and a full native hours/contact/photo check. PR #31 is included in the release branch.
- Two-phone acceptance is agreed with the user and remains pending a distributable build.

Apple references: [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [App record workflow](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow/), [TestFlight](https://developer.apple.com/testflight/), and [automatic distribution profiles](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/). Storage limits: [Supabase file limits](https://supabase.com/docs/guides/storage/uploads/file-limits).
