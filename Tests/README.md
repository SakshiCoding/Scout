Run the credential-free regression harness on macOS with Xcode command-line tools:

```sh
Tests/run-metadata-tests.sh
```

It compiles the production Gemini service and restaurant/import models directly, then tests them with URLProtocol fixtures. No Xcode project changes, test dependencies, credentials, or live API requests are needed.

Simulator build:

```sh
xcodebuild -project Scout.xcodeproj -scheme Scout -sdk iphonesimulator \
  -configuration Debug -derivedDataPath /tmp/scout-derived \
  CODE_SIGNING_ALLOWED=NO build
```

UI walkthrough with a configured Gemini key and signed-in circle (requires local credentials; not covered by the harness):

- Open Add restaurant and choose a Places match with no specific cuisine. Suggestions should fill an empty cuisine and select editable vibe chips; an uncommon cuisine appears in Other.
- Choose a match with a specific cuisine. Its cuisine should remain selected; name suggestions can still be requested explicitly.
- Type a restaurant name without choosing a place and tap Suggest cuisine & vibes. Unknown/ambiguous names should leave the form editable with a no-confident-suggestions message.
- While suggestions are loading, select or clear cuisine/vibe chips (including toggling back to empty). The response must preserve those choices. Custom Other text and changing type also protect cuisine.
- While loading, change the name, clear the place, select another place, or dismiss the sheet. Old suggestions must not be applied. Changing a name removes untouched generated details.
- Save while suggestions are loading. Saving must proceed with the current form values without waiting for Gemini.
- Remove GEMINI_API_KEY and rebuild. The suggestion control should be absent and Places/manual add should still work. With a bad key or offline connection, the form should show fallback text and still allow saving.

## Scout Home Screen widget

Run snapshot/store regressions (no credentials or network requests):

```sh
Tests/run-widget-tests.sh
```

Render the production layout in small/medium sizes across ready, signed-out, no-circle, empty, and stale states. The ready fixture includes a long restaurant/circle name:

```sh
Tests/render-widget-previews.sh /tmp/scout-widget-previews
```

For App Group integration in Simulator, build with simulator signing enabled so the App Group entitlements are included:

```sh
xcodebuild -project Scout.xcodeproj -scheme Scout -sdk iphonesimulator \
  -configuration Debug -derivedDataPath /tmp/scout-derived \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build
xcrun simctl install booted /tmp/scout-derived/Build/Products/Debug-iphonesimulator/Scout.app
xcrun simctl launch booted com.sakshisangani.Scout
xcrun simctl get_app_container booted com.sakshisangani.Scout groups
```

After opening Scout once, add **Scout Wishlist** from the Home Screen widget gallery. Check both sizes: small shows the newest saved restaurant; medium shows up to three, with circle name and the full wishlist count. Long names should truncate without displacing the metadata. Tap to open List / Want to try with filters reset. `xcrun simctl openurl booted scout://wishlist` exercises the same destination.

With a signed-in session, switch circles, add/edit/delete a restaurant, and mark one visited; the widget should reflect the next local snapshot after WidgetKit grants the reload. Sign-out must remove saved widget data. Changes by other circle members require an app refresh. No network requests or credentials are used by the extension itself.

For synthetic gallery data without logging in, terminate Scout, then run `Tests/run-widget-tests.sh --fixture /path/to/the/AppGroup/container` using the directory reported by `get_app_container ... groups`. This overwrites only the local widget snapshot with test restaurants. Relaunch Scout afterward to restore its real snapshot (or clear it when signed out).

Device signing requires registering `com.sakshisangani.Scout.WidgetExtension` with the same `group.com.sakshisangani.Scout` App Group as the app. Simulator signing does not verify Apple Developer provisioning for a physical device.

## Real partner matching

Install the pinned database-test dependency once, then run the SQL and Swift tests:

```sh
npm ci --prefix Tests/database --ignore-scripts
Tests/run-pick-tests.sh
```

The harness applies the original matching migration and both shared-pick follow-up migrations to an isolated PGlite Postgres database with fixture auth users/circles. It runs requests as distinct authenticated roles and verifies shared decks, genuine unanimity, disagreement, ordered votes, undo, retries, stale requests, shared rematches, membership/day changes, and RLS/permission failures for forged votes or matches. It then decodes a real SQL result with the production Swift models. No hosted database, credentials, or production records are used. PGlite serializes transactions within one process; this verifies the rematch retry protocol but does not stress multiple concurrent backend connections.

Scout's hosted project (`vdhhsxgirkjalysejycw`) was deployed and verified on October 26, 2026. Other environments require these migrations in order:

- `20261020230236_real_partner_matching.sql`: tables, member-read policies, checked RPC, and Realtime publication membership.
- `20261027011354_optimize_shared_pick_read_policy.sql`: cache the caller identity for session SELECT policy evaluation.
- `20261027011514_fix_shared_pick_stale_round_error.sql`: use `PT409` / HTTP 409 for stale rounds. SQLSTATE `40001` can cause an infinite hosted PostgREST retry loop; the local test checks the exact error code.

Hosted verification passed with two independent member sessions and an outsider: shared decks, single-vote non-match, duplicate retries, undo, concurrent unanimous voting, restored match, simultaneous rematches, immediate stale-round HTTP 409, disagreement, outsider RLS isolation, denied forged votes/winners, anonymous RPC denial, and WebSocket delivery of the partner's revision. Disposable accounts/circle/restaurants were removed afterward; existing user records were untouched.

To repeat the opt-in hosted checks, create a dedicated disposable circle with exactly two members, three unvisited restaurants, no existing votes, and a third account outside that circle. Put the following configuration in a private file outside the repository (use the public client key, never a service-role key):

```json
{
  "disposable": true,
  "url": "https://PROJECT.supabase.co",
  "anonKey": "PUBLIC_CLIENT_KEY",
  "circleId": "DISPOSABLE_CIRCLE_UUID",
  "accounts": [
    {"userId": "MEMBER_A_UUID", "email": "MEMBER_A_EMAIL", "password": "PASSWORD"},
    {"userId": "MEMBER_B_UUID", "email": "MEMBER_B_EMAIL", "password": "PASSWORD"},
    {"userId": "OUTSIDER_UUID", "email": "OUTSIDER_EMAIL", "password": "PASSWORD"}
  ]
}
```

```sh
SCOUT_PICK_TEST_CONFIG=/private/path/scout-test.json node Tests/database/hosted-partner-matching.test.mjs
```

Requires Node 22 or newer. The harness signs in through Auth and mutates only the supplied circle's rounds/votes. It requires the fixture to start fresh, waits for the Realtime subscription readiness event before voting, and bounds network requests. Remove the disposable circle and accounts and delete the private configuration afterward.

Two-device walkthrough after deployment:

- Sign in as two different members of the same circle. Open Pick on both; they must see the same deck/order even if their device time zones differ. No progress appears for a member who has not voted.
- Say yes on only one device: no match. Say yes on the same place on the other device: both reveal the same saved match. Reopen Pick to restore it.
- Skip on one device and yes on the other: no false match. Finish the deck on both without agreement to enable a shared new round.
- Undo the most recent vote before matching, including from the waiting screen, and verify the other member's progress updates. A completed match is locked until rematch.
- Trigger Pick again on both devices from the same resolved round. Both must join the same new round with votes cleared. A delayed vote for the old round must fail.
- Lose connectivity while voting: the card must not advance without acknowledgement. Restore connectivity; the next snapshot must reconcile a vote that may have committed before its response was lost. Disable Realtime to confirm the five-second foreground polling fallback.
- Switch circles, sign out, background, and reopen while updates are in flight. No response from the old circle/scope may replace the active round. Add/remove a member to regenerate the participant set; a three-member round needs three yes votes.
- With only one member, show the invitation guidance and never produce a match. With no candidates, show the empty-wishlist state. Mark a deck restaurant visited/delete it or advance the server's UTC day to verify invalidation.

Hosted Auth/PostgREST/Realtime checks and a signed Simulator build passed. Physical two-device UI interaction, provisioning, and connectivity gestures remain manual checks; the hosted harness does not claim to exercise those UI paths.


## Siri / App Shortcuts

```sh
Tests/run-shortcut-tests.sh
```

The harness compiles the production App Intents, typed routes, navigation extension, and filter models. It injects a service-free AppState fixture for direct `perform()` calls (Apple's dependency injection flow does not run when calling this method directly). It verifies three foreground actions, intended tabs, repeated requests, wishlist reset, filter preservation, and URL routing that leaves auth/import links with their existing handlers. It does not test live AppDependencyManager resolution, auth lifecycle, speech recognition, or the Shortcuts UI.

A signed Simulator build passed with three discoverable foreground intents, three tiles, and six extracted phrases. To validate the compiled artifact too, pass its metadata file:

```sh
Tests/run-shortcut-tests.sh /tmp/scout-derived/Build/Products/Debug-iphonesimulator/Scout.app/Metadata.appintents/extract.actionsdata
```

Simulator walkthrough completed October 26, 2026: all three actions appeared in Apple's Shortcuts app and launched Scout through the normal sign-in gate. A cold journal action retained its destination through a real disposable-account sign-in. Authenticated picker/wishlist actions opened the correct screens, the picker created zero votes/matches, and repeated wishlist execution restored want-to-try from Visited. The hosted fixture account, circle, restaurant, and pick session were removed afterward. The test account's password was not saved in Passwords.

Physical-device walkthrough:

1. Install and open Scout, then find Scout under App Shortcuts in Apple's Shortcuts app. Expect Open wishlist, Pick a restaurant, and Open journal.
2. Run each action while Scout is open and from a terminated launch. Each action should foreground the existing screen for the active/restored circle. Signed-out launches must show sign-in before displaying circle data and continue to the requested section after sign-in.
3. In the wishlist select Visited, apply filters, and open a restaurant. Run Open wishlist: return to the want-to-try list root with filters cleared. Repeat the same action.
4. Push a restaurant scrapbook from Journal, then run Open journal: return to the journal index. Opening Pick or Journal should preserve wishlist filters.
5. Run Pick a restaurant with two members and verify it only opens the shared round; it must not submit a vote, declare a match, or reset an existing round.
6. Try “Open my wishlist in Scout,” “Pick a restaurant in Scout,” and “Open my journal in Scout” with Siri on a physical device. Speech recognition, Siri language/settings, and indexing are system-controlled and are not verified by the command-line harness.
7. Confirm the widget's `scout://wishlist`, share extension's import handoff, and password-reset callback continue to work. `scout://pick` and `scout://journal` are additional navigation links.


## Atlas app icon and branding

```sh
swift Tests/validate-brand-assets.swift
swift Tests/validate-brand-assets.swift /tmp/scout-derived/Build/Products/Debug-iphonesimulator/Scout.app
```

The source checks cover all three iOS appearance slots, 1024px dimensions, opaque light/tinted PNGs, transparent dark background, exact sRGB Atlas paper/burnt-orange samples, grayscale tinted input, and vector PDF/template configuration. The optional bundle path checks compiled icon metadata and renditions. Regenerate assets together with `swift Scripts/generate-brand-assets.swift`; see `Branding/README.md` for the editable geometry and preview.

Simulator verification completed October 26, 2026: signed Debug build, source/compiled icon checks, default/dark/tinted Home Screen appearances on a fresh iOS 26.4 Simulator, and the sign-in compass rendered correctly. Its accessibility tree contains the Scout heading without a duplicate decorative mark. The disposable Simulator was removed after testing. Existing shortcut and widget regression harnesses passed. No hosted data or credentials were changed.

Release walkthrough:

- Install Scout and confirm its compass/fork icon replaces the blank placeholder on the Home Screen and in system app surfaces.
- Launch while signed out: the sign-in screen should show the same compass, with the existing Scout heading and layout. Auth loading uses a smaller version. VoiceOver should announce the heading without a duplicate decorative image label.
- Check dark and tinted Home Screen appearances on a device. The dark glyph should appear over the system background; tinted should remain legible under the chosen tint. The contact sheet previews the grayscale source rather than any user tint.
- Verify widget and Shortcuts discovery still work, and run normal archive/App Store validation before distribution. Simulator checks do not verify physical-device appearance, provisioning, or App Store acceptance.
