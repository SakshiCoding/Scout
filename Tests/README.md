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

The harness applies `20261020230236_real_partner_matching.sql` to an isolated PGlite Postgres database with fixture auth users/circles. It runs requests as distinct authenticated roles and verifies shared decks, genuine unanimity, disagreement, ordered votes, undo, retries, stale requests, shared rematches, membership/day changes, and RLS/permission failures for forged votes or matches. It then decodes a real SQL result with the production Swift models. No hosted database, credentials, or production records are used. PGlite serializes transactions within one process; this verifies the rematch retry protocol but does not stress multiple concurrent backend connections.

Before a hosted/device walkthrough, apply the new migration to **Scout's** Supabase project. It creates two tables, member-read policies, a checked RPC, and Realtime publication membership. It does not change legacy `picks` rows. This PR does not deploy the migration to Scout; the connected account did not include that project.

Two-device walkthrough after deployment:

- Sign in as two different members of the same circle. Open Pick on both; they must see the same deck/order even if their device time zones differ. No progress appears for a member who has not voted.
- Say yes on only one device: no match. Say yes on the same place on the other device: both reveal the same saved match. Reopen Pick to restore it.
- Skip on one device and yes on the other: no false match. Finish the deck on both without agreement to enable a shared new round.
- Undo the most recent vote before matching, including from the waiting screen, and verify the other member's progress updates. A completed match is locked until rematch.
- Trigger Pick again on both devices from the same resolved round. Both must join the same new round with votes cleared. A delayed vote for the old round must fail.
- Lose connectivity while voting: the card must not advance without acknowledgement. Restore connectivity; the next snapshot must reconcile a vote that may have committed before its response was lost. Disable Realtime to confirm the five-second foreground polling fallback.
- Switch circles, sign out, background, and reopen while updates are in flight. No response from the old circle/scope may replace the active round. Add/remove a member to regenerate the participant set; a three-member round needs three yes votes.
- With only one member, show the invitation guidance and never produce a match. With no candidates, show the empty-wishlist state. Mark a deck restaurant visited/delete it or advance the server's UTC day to verify invalidation.

Hosted PostgREST/Realtime and physical two-device interactions remain manual integration checks; local SQL tests and the simulator build do not verify that the hosted migration/publication is deployed.
