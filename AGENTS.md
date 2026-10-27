# Scout — Codex Development Guide

> **Standing rule:** After implementing any feature, always update CLAUDE.md and AGENTS.md to reflect what was built — file table, UI screens table, Phase checklist. This is automatic, not optional, and does not need to be prompted by the user each time.

> **Feature delivery workflow:** Every request for a new feature includes implementation, testing, opening a pull request, and merging it once verification passes and merging is available. Do this automatically without another prompt. If verification or merging is blocked, report the blocker and leave the PR open.

Scout is a shared restaurant wishlist iOS app organized around **circles** — named groups (couples, families, roommates, travel crews) each with their own wishlist, map, swipe picker, and photo journal. Built with SwiftUI + Supabase + Google Maps SDK for iOS + CoreLocation + Google Places SDK for iOS + Google Gemini API.

---

## Current State

The project is **not** a bare SwiftUI shell anymore. Phase 1 is foundation-complete. Phase 2 now includes Places enrichment, the map, visited logging, and the first journal slice. Phase 3 has started with the Safari/Apple Maps share-import backbone and Gemini social parsing: SwiftUI app structure, shared state, Supabase integration, authentication, circle switching, wishlist UI, manual restaurant add, bulk import, filters, Atlas design-system helpers, visit records, journal loading, journal browsing, share capture, import review, `GeminiService`, TikTok/Instagram/social import autofill, optional name-based cuisine/vibe suggestions in the add form, the first Scout Home Screen widget, server-authoritative circle matching (deployed to Scout), Siri/App Shortcuts navigation, Atlas app icons/shared branding assets, and secure circle invitations are implemented.

| File | Status |
|------|--------|
| `Scout/ScoutApp.swift` | App entry point; creates and injects one `AppState` into SwiftUI and App Intents dependencies |
| `Scout/Intents/ScoutShortcuts.swift` | Three foreground Siri/App Shortcuts: open wishlist, open shared picker, and open journal; routes through the existing AppState/auth gate |
| `Scout/Models/ScoutDestination.swift` + `Scout/AppState/AppState+Navigation.swift` | Shared typed destinations/tab enum and navigation for shortcuts and `scout://wishlist`, `scout://pick`, `scout://journal` links |
| `Scout/Models/WishlistFilter.swift` | Existing wishlist tab/filter types, moved unchanged from AppState for reuse and credential-free navigation tests |
| `Scout/AppState/AppState.swift` | Main app state for auth, circles, restaurants, filtering, visits, media, journal summaries, services, Google Place detail refreshes, shared import state/debug fixtures, shared pick state (`pickSession`, `observePickSession`, `sendPickAction`, derived `activePickMatch`), scoped Realtime observation, and stale-response guards, widget snapshot publishing, sign-out cleanup, wishlist widget links, pending invitation handoff, circle-load request guards, and joined-circle count refresh |
| `Scout/Services/SupabaseService.swift` | Supabase client and core circle/restaurant/visit/media/profile/pick methods; persists Google Place IDs, includes journal reads, private storage downloads, nested member snapshots via `scout_my_circles`, and the checked `sharedPick` RPC for shared decks, votes, undo, rematches, and authoritative matches |
| `Scout/Models/CircleInvitation.swift` | Strict invitation code/link parser and management/preview response models; CircleMember decoding preserves legacy members with null initials using a placeholder |
| `Scout/Services/SupabaseService+Invitations.swift` + `Scout/AppState/AppState+Invitations.swift` | Checked invitation RPCs and acknowledged join flow; refresh authoritative circle/member snapshots, switch to the joined wishlist, and reject stale auth/circle-load responses |
| `Scout/Views/Circles/InviteCircleSheet.swift` + `Scout/Views/Circles/JoinCircleSheet.swift` | Create/share/copy/replace/revoke seven-day invites; paste/check/confirm joining, including links opened before sign-in |
| `Tests/run-invitation-tests.sh` + `Tests/database/hosted-circle-invitations.test.mjs` | Real migration/pgcrypto permission and lifecycle tests, Swift parser/SQL decoding tests, and opt-in hosted Auth/PostgREST/concurrency integration checks |
| `Scout/Services/AuthService.swift` | Auth session handling, email/Apple sign-in, password-reset email requests, recovery callback sessions, and password updates |
| `Scout/Services/LocationService.swift` | Location permissions, tap-triggered current-location requests, immediate post-authorization location refresh, and distance sorting |
| `Scout/AppState/AppState+RestaurantLoading.swift` + `Scout/Services/RestaurantEnrichment.swift` | Saved restaurants publish before optional Places refresh; at most three detail requests per refresh run concurrently, preserving order/fallbacks. Request/user/circle/revision guards protect local changes and reject stale responses; scope changes clear the previous circle and stop scheduling old refresh work. |
| `Scout/Services/MediaService.swift` + `MediaThumbnailStore.swift` + `MediaThumbnailRenderer.swift` | Shared private-media thumbnails: 512px photo downsampling with EXIF orientation, size-limited rotated video posters, detached decoding, duplicate-load coalescing, 32MB advisory decoded cache budget/128-item limit, deletion invalidation, and sign-out cleanup; original-media sharing is preserved |
| `Tests/run-media-thumbnail-tests.sh` + `Tests/MediaThumbnailTests.swift` | Credential-free macOS and iOS Simulator tests using real ImageIO/AVFoundation photo/video fixtures plus deferred downloads for cache, coalescing, retry, cancellation, deletion, and sign-out races |
| `Scout/Services/PlacesService.swift` | Google Places Text Search (New) with Apple local-search fallback; returns Scout-owned place results, enrichment hints (expanded cuisine mapping: 25 types including Seafood, Steakhouse, BBQ, Spanish, Middle Eastern, Brazilian, Indonesian, Lebanese, Turkish; vibe hints from fine dining, fast food, brunch, sports bar types), and Google website/phone contact details |
| `Scout/Services/GoogleMapsConfiguration.swift` | Configures Google Maps SDK from the shared Maps Platform API key |
| `Scout/Services/GeminiService.swift` | Google Gemini API client foundation for structured restaurant extraction from shared TikTok/Instagram/social text; reads `GEMINI_API_KEY`/`GEMINI_MODEL`, requests JSON output, normalizes restaurant name, city/neighborhood, cuisine, establishment type, price tier, vibe tags, note, and confidence; includes conservative name/address-based cuisine and canonical vibe suggestions with confidence gating |
| `Scout/Views/Shared/AtlasPrimaryButtonStyle.swift` | Atlas 52pt pill button style with shared typography, disabled state, and pressed feedback for invitation CTAs |
| `Scout/Views/Shared/ScoutBrandMark.swift` | Shared decorative vector compass/fork mark used by sign-in, first-circle, and auth-loading screens; Atlas tint and existing layout preserved |
| `Scout/Assets.xcassets/` + `Branding/` | iOS light/dark/tinted app icons, vector compass PDF/SVG, Atlas accent color, preview contact sheet, and branding/regeneration guide |
| `Scripts/generate-brand-assets.swift` + `Tests/validate-brand-assets.swift` | Native Core Graphics asset generation and checks for icon slots, dimensions, transparency, exact sRGB palette, grayscale tint, vector configuration, and compiled bundle icon packaging |
| `Scout/Theme/AtlasTheme.swift` | Direction A "Atlas" colors, typography, layout constants, and shadows |
| `Scout/Models/SharedRestaurantImport.swift` | Shared app/extension import payload + App Group storage for pending restaurant/social shares |
| `Scout/Views/Root/RootView.swift` | Auth gate, custom tab shell, shared import sheet host, debug-only social import test button, and shortcut-driven list/journal navigation reset, a shared Atlas compass on the loading screen, and a shared incoming-sheet host for auth-gated invitation/import review |
| `Scout/Views/Root/CustomTabBar.swift` | Floating custom tab bar; do not replace with SwiftUI `TabView` |
| `Scout/Views/Auth/SignInView.swift` | Apple/email authentication with friendly error mapping, password-reset email action, and shared Atlas compass brand mark |
| `Scout/Views/Auth/ResetPasswordView.swift` | Recovery-link destination for choosing and saving a new password |
| `Scout/Views/Wishlist/` | Wishlist, add restaurant, bulk import, filters, and restaurant rows; add form automatically requests Gemini cuisine/vibe suggestions for generic Places results and offers a manual suggestion button, preserving user edits and rejecting stale responses |
| `Tests/run-restaurant-loading-tests.sh` + `Tests/RestaurantLoadingTests.swift` | Deferred-service regressions for the production loader/scheduler: early saved-data publication, bounded concurrency, edit-safe merges, stale scopes, failures, and cancellation |
| `Tests/` | Credential-free restaurant-loading, Gemini, widget, and shared-pick regression harnesses; `run-pick-tests.sh` runs the matching migrations in PGlite Postgres with multiple auth identities, then decodes its snapshot in Swift; opt-in hosted Auth/PostgREST/Realtime checks are in `Tests/database/hosted-partner-matching.test.mjs`; see `Tests/README.md` |
| `Scout/Views/Import/ImportReviewView.swift` | Main-app import review sheet for shared Safari/Apple Maps/Google Maps/TikTok/Instagram places: circle selection, Gemini-powered social text prefill, Places match suggestions, manual fallback when no match is found, note, and save |
| `Scout/Views/Detail/RestaurantDetailView.swift` | Detail screen: hero placeholder, title, stat row, note, vibe tags, edit sheet, mark visited button, visited-journal shortcut, and reservation/contact actions |
| `Scout/Views/Detail/MarkVisitedSheet.swift` | Lightweight post-visit bottom sheet: circle kicker, restaurant heading, 1–5 star rating, photo picker, italic note field, Save/Skip CTAs |
| `Scout/Views/Map/MapView.swift` | Google Maps SDK map wrapper, custom Atlas markers, camera controls, filters, user-location permission trigger, and restaurant peek card |
| `Scout/Views/Journal/` | Journal index, per-restaurant scrapbook, full composer, fullscreen viewer, and cross-post sheet with real visit/media loading, cached photo/video thumbnails, editable metadata, attachments, swipe paging, video playback, sharing, deletion, and moving accidentally visited places back to the wishlist |
| `Scout/Views/Pick/PickerView.swift` | Swipe pick tab backed by a server-owned deck and real circle-member votes; acknowledged progress, per-member status, waiting/no-match states, undo, shared rematch, and persistent match reveal; foreground Realtime updates plus five-second refresh fallback |
| `Scout/Views/Pick/MatchView.swift` | Match reveal screen: animated heading + restaurant card + member avatars + "Let's go!" (`onConfirm`) / "Pick again" (`onPickAgain`) two-callback CTAs |
| `Scout/Views/Circles/` | Circle switcher/picker with refreshed real member lists, new circle, invite management, and join sheets; first-circle and solo-picker entry points |
| `Scout/Views/Shared/` | Shared small UI components and Atlas icons |
| `ScoutShareExtension/` | Share Extension target: captures URL/text from Safari, Apple Maps, Google Maps, TikTok, Instagram, and other social links; supports Apple Maps MapKit place payloads; safely parses place hints/coordinates from shared links and text, expands Google Maps short links when possible, applies first-pass social caption cleanup, writes a pending import through the App Group, and opens Scout |
| `Scout/Models/` | Circle, restaurant, visit, and media models |
| `Scout/Models/SharedPickSession.swift` | Shared round/vote Codable models, monotonic revision guard, time-window labels, and read-only `PickSession` projection; no synthetic votes or client-declared winner |
| `Scout/Models/ScoutWidgetSnapshot.swift` | Bounded active-circle wishlist projection and atomic App Group file store; no credentials, notes, or media; signed-out, no-circle, empty, ready, and 24-hour stale states |
| `ScoutWidgetExtension/` | Embedded WidgetKit extension with small/medium Home Screen wishlist layouts, timeline provider, shared Atlas theme/fonts, App Group entitlement, and `scout://wishlist` link |

Supabase Swift, Google Places SDK, and Google Maps SDK are added through Swift Package Manager. Do not remove or recreate package dependencies unless the task explicitly requires it.

### Architecture Preservation Rules

Before making changes, read the current files related to the task and preserve the existing architecture. Do **not** start over from a blank template, replace the app shell, rewrite the design system, or discard existing Phase 1 work.

- Extend `AppState` instead of creating parallel global state.
- Use `Atlas` colors, fonts, layout constants, and shared components instead of inventing a second design system.
- Keep `RootView` + `CustomTabBar` as the main navigation shell.
- Keep `CircleSwitcherPill` as the top circle control across screens.
- Build new screens in the target folders while matching existing SwiftUI patterns.
- Avoid broad rewrites of `Scout.xcodeproj/project.pbxproj`; Xcode project changes are conflict-prone when multiple people are working.
- Treat existing user/coworker changes as intentional. Do not revert unrelated files.
- If a file appears stale or inconsistent with this guide, inspect the codebase and favor the current working implementation.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift |
| UI | SwiftUI |
| Database + Auth + Storage | Supabase (Postgres + Supabase Auth + Supabase Storage) |
| Auth method | Sign in with Apple → Supabase Auth |
| Maps | Google Maps SDK for iOS |
| Location | CoreLocation |
| Places enrichment | Google Places SDK for iOS (Text Search New), with Apple local-search fallback |
| AI parsing | Google Gemini API (Phase 3 only — TikTok captions) |
| Notifications | UserNotifications |
| Extensions | Share Extension, WidgetKit |

---

## Design System — Direction A "Atlas" (chosen)

Warm editorial aesthetic: cream paper, burnt orange accents, DM Serif Display headings, DM Sans UI text.

### Colors

| Token | Value | Use |
|-------|-------|-----|
| Paper | `#F7F1E6` | Main background |
| Paper2 | `#EFE6D4` | Cards, inputs, note fields |
| Ink | `#1B1612` | Primary text, filled buttons |
| Ink2 | `rgba(27,22,18,0.62)` | Secondary text |
| Ink3 | `rgba(27,22,18,0.42)` | Muted/disabled text |
| Rule | `rgba(27,22,18,0.10)` | Hairline dividers |
| Burnt Orange | `#CC5500` | Primary accent — active states, CTAs, index numerals |
| Orange | `#E5651C` | Secondary accent |

Circle accent colors (built-in set): Burnt Orange `#CC5500` · Sage `#7A8B3C` · Slate `#3D5A80`

Status dot colors: green = open · burnt orange = closes soon · Ink3 = opens later

### Typography

- **DM Serif Display** — page headings, index numerals (01 02 03), italic title words
- **DM Sans** — all labels, metadata, buttons, chips

| Purpose | Size | Weight | Notes |
|---------|------|--------|-------|
| Page title | 44pt | 400 | Serif. "Your *atlas*" — italic word in burnt orange |
| Detail name | 40pt | 400 | Serif |
| Pick heading | 36pt | 400 | Serif, italic accent word |
| Journal heading | 56pt | 400 | Serif |
| Section title | 28pt | 400 | Serif |
| Card name | 20pt | 400 | Serif |
| Index numeral | 22pt | 400 | Serif, burnt orange |
| Metadata | 12.5pt | 400 | Sans — cuisine · price · rating |
| Uppercase label | 10.5–11pt | 500–600 | Sans, 1.4–1.6pt letter-spacing |
| Button | 13–14.5pt | 600 | Sans |
| Caption | 9.5–11pt | 400 | Sans |

### Layout Constants

| Token | Value |
|-------|-------|
| Screen horizontal padding | 16–24pt |
| Tab bar height | 60pt |
| Tab bar bottom offset | 22pt |
| Tab bar corner radius | 30pt |
| Circle pill height | 36–38pt |
| Filter chip height | 26pt, 11pt H-padding |
| Primary button height | 50–52pt, 99pt radius (pill) |
| Card corner radius | 22–28pt |
| Restaurant thumbnail | 64×76pt, 10pt radius |
| Active tab dot | 4pt circle below icon, burnt orange |
| Tab icon size | 22pt, 1.6pt stroke |

### Shadows

```
Card:        0 1px 3px rgba(0,0,0,0.08), 0 4px 16px rgba(0,0,0,0.06)
Tab bar:     0 10px 30px rgba(50,30,10,0.18), 0 0 0 1px rgba(27,22,18,0.08)
Bottom sheet: 0 -8px 30px rgba(15,10,5,0.25)
```

---

## Target Folder Structure

Build toward this layout as files are created:

```
Scout/
  Models/
    Circle.swift
    Restaurant.swift
    Visit.swift
    Media.swift
  Services/
    SupabaseService.swift
    LocationService.swift
    PlacesService.swift
    GeminiService.swift       ← Phase 3 only
    MediaService.swift
  Views/
    Wishlist/
      WishlistView.swift
      RestaurantRowView.swift
      AddRestaurantView.swift
      BulkImportView.swift
      FilterSheetView.swift
    Detail/
      RestaurantDetailView.swift
      MarkVisitedSheet.swift
    Map/
      MapView.swift
    Pick/
      PickerView.swift
      MatchView.swift
    Journal/
      JournalIndexView.swift
      JournalLocationView.swift
      JournalComposeView.swift
      JournalViewerView.swift
      CrossPostSheet.swift
    Circles/
      CirclePickerSheet.swift
      CircleSwitcherPill.swift
  Extensions/                  ← Share Extension target (Phase 3)
  Widgets/                     ← WidgetKit target (Phase 3)
```

---

## Supabase Schema (tables)

`profiles` · `circles` · `circle_members` · `restaurants` · `visits` · `media` · `picks` (legacy) · `pick_sessions` · `pick_votes` · `circle_invitations`

The schema lives in `supabase/migrations/`. Current circle and restaurant creation/loading use Supabase RPC functions to avoid client-side RLS timing issues:

- `create_circle`
- `scout_my_circles` (nested real membership snapshots; legacy `get_my_circles` retained for older apps)
- `scout_circle_invite` (status/create/revoke/preview/join)
- `add_restaurant`
- `get_circle_restaurants`
- `add_visit`
- `mark_visited`
- helper: `is_circle_member`

Journal photos and videos use the private `scout-media` Supabase Storage bucket. Migration `20260601000000_add_scout_media_storage_policies.sql` creates the bucket and circle-member read/upload/delete policies. Migration `20260601001000_add_visit_journal_fields.sql` adds visit `occasion` and `vibe_tags` fields and extends the `add_visit` RPC payload. Migration `20260601002000_repair_journal_media_policies.sql` idempotently repairs storage and `public.media` policies for databases whose initial schema was applied manually. Migration `20260601003000_repair_journal_visit_policies.sql` repairs `public.visits` read/write policies so persisted entries remain visible after reload. Apply pending migrations before testing journal entry creation or media upload/download.

Migration `20260604000000_add_google_places_metadata.sql` adds `google_place_id` to restaurants and extends the `add_restaurant` RPC. Scout persists Place IDs for Google-linked restaurants, then refreshes Google address and coordinates into memory for display on the Google map instead of treating cached coordinates as the long-term source of truth. To enable the integration, enable Places API (New) and Maps SDK for iOS in Google Cloud, create an iOS-restricted API key for Scout's bundle identifier, and set `GOOGLE_MAPS_API_KEY` in the ignored `Scout/Config.xcconfig` file. Use `Scout/Config.example.xcconfig` as the template.

Confirmed journal visits and uploaded media are merged into `AppState` immediately and preserved while the network refresh reconciles with Supabase. Keep this optimistic merge behavior when changing journal loading so a delayed response cannot make a newly saved entry disappear.

---

## UI Screens

Some Phase 1 screens are already implemented or partially implemented. Full specs live in `Scout/SPEC.md`, with pixel-accurate React mockups in the design files listed below. When implementing a screen, compare the relevant SwiftUI files against the spec and extend what exists.

| # | View name | Tab | Status | Purpose |
|---|-----------|-----|--------|---------|
| 1 | `WishlistView` | List | Implemented/active | Home — group's restaurant wishlist sorted by distance; saved data appears before Places detail refresh, and failed refreshes retain loaded places; add flow uses Google Places search and persists Place IDs when configured; Gemini fills cuisine/vibe gaps for generic results, with editable suggestions and a manual name-based action; the first-circle empty state also offers Join a circle |
| 2 | `RestaurantDetailView` | — | Implemented (Phase 2 partial) | Hero placeholder, name, cuisine, price, stats, notes, vibe tags, edit sheet, mark visited, visited-journal shortcut, OpenTable/Resy search links, and Google website/phone actions when available |
| 3 | `PickerView` + `MatchView` | Pick | Implemented / hosted verified | All members share one server-created deck of up to three places. A match requires yes from every round participant (minimum two); actual member progress syncs via Realtime with polling recovery. Votes/matches resume on reopen; undo is allowed before a match; shared rematches are serialized. No simulated partner or UserDefaults match fallback. |
| 4 | `MapView` | Map | Implemented | Full-bleed Google map with custom Atlas pins, glass header, bottom peek card, tap-triggered user location, and filter wiring; saved pins appear before bounded Places detail refresh |
| 5 | `CirclePickerSheet` | — | Implemented/active | Bottom sheet — switch circles, view refreshed member avatars, invite to the active circle, or join another |
| 6 | `JournalIndexView` | Journal | Implemented/active | Table of contents for visited restaurants, enriched with real visit/media stats, recent-first rows, circle switching, memory-conscious thumbnails, and blank-polaroid empty state |
| 7 | `JournalLocationView` | — | Implemented | Per-restaurant scrapbook with visit dates, occasion labels, photo polaroid clusters with downsampled shared thumbnails, notes, empty state, compose action, destructive entry deletion, and moving a place back to the wishlist |
| 8 | `JournalComposeView` | — | Implemented | Full-screen new entry flow: editable date, occasion, note, vibe chips, removable photo/video attachments, and save |
| 9 | `JournalViewerView` | — | Implemented | Fullscreen dark photo/video viewer with swipe paging, page dots, caption block, shared downsampled thumbnail strip, close/share/overflow controls, deletion, and native video playback |
| 10 | `MarkVisitedSheet` | — | Implemented | Auto-prompted after "Mark as visited" — rating, photos, and visit note; "Save to journal" creates a Visit record and uploads photos, "Skip for now" marks visited only |
| 11 | `CrossPostSheet` | — | Implemented | Copy a journal photo/video into another circle's matching restaurant journal or share externally through iOS |
| 12 | `ImportReviewView` | — | Implemented | Main-app review sheet launched from the Share Extension or debug simulator test hook; confirms Safari/Apple Maps/Google Maps/TikTok/Instagram imports, uses Gemini to prefill social restaurant hints, chooses circle, matches Google/Apple Places results, keeps manual name edits, and saves to wishlist even when no exact match is found |
| 13 | `ResetPasswordView` | — | Implemented | Full-screen password recovery form opened by Supabase email links through `scout://password-reset` |
| 14 | `ScoutWidgetView` | Home Screen | Implemented | Small widget shows the newest saved place; medium shows up to three, with active circle and total wishlist count; handles sign-in/no-circle/empty/stale states and opens the existing List tab |
| 15 | `ScoutShortcuts` | Siri / Shortcuts | Implemented | Three discoverable actions open the existing wishlist, Pick, or journal index; wishlist resets filters, journal resets its navigation stack, and signed-out launches keep the sign-in gate |
| 16 | `ScoutBrandMark` + app icon | Auth / Home Screen | Implemented | Atlas compass with fork motif replaces the placeholder S on sign-in/first-circle/loading; light, dark, and tinted iOS icons use the same geometry |
| 17 | `InviteCircleSheet` | — | Implemented / hosted verified | Members create a seven-day link/code, share or copy it, replace the active link, and revoke future joins |
| 18 | `JoinCircleSheet` | — | Implemented / hosted verified | Paste a code/link or continue after auth from a deep link, preview the circle, explicitly confirm joining, then open its wishlist |

### Key layout rules across all screens

- Every screen has a `CircleSwitcherPill` pinned at the top
- Tab bar is a **floating custom component** (not SwiftUI's `TabView`) — 4 tabs: List · Map · Pick · Journal
- Bottom sheets use drag handle + 24pt top radius + `rgba(15,10,5,0.55)` dimmed overlay
- "Glass" variants of the circle pill (on hero photos and map) use `backdrop-filter: blur(10px)` equivalent

---

## Development Phases

### Phase 1 — Foundation — Complete
> Core data model, auth, circles, basic wishlist end to end

- [x] Supabase schema (profiles, restaurants, visits, media, circles, circle_members)
- [x] Sign in/auth foundation + Supabase Auth integration + complete email password recovery
- [x] Circles data model + circle switching
- [x] Restaurant model + SupabaseService foundation
- [x] WishlistView
- [x] AddRestaurantView (manual add)
- [x] BulkImportView (paste list to import)
- [x] LocationService + distance sorting foundation
- [x] RestaurantRowView
- [x] Tag/filter foundation (cuisine, vibe, price)
- [x] FilterSheetView
- [x] CirclePickerSheet + CircleSwitcherPill

Phase 1 verified behavior:

- App restores existing circles after restart.
- Manual restaurant add persists.
- Bulk import persists.
- Wishlist rows appear immediately after add/import and reload after restart.
- Filter apply, reset, and clear work for available metadata.

### Phase 2 — Enrichment & Core Features
> Make the app genuinely useful day-to-day

- [x] PlacesService (Google Places SDK Text Search New, persisted Place IDs, transient location enrichment, cuisine/type hints, and Apple local-search fallback)
- [x] RestaurantDetailView — partial (hero placeholder, info, edit, mark visited, delete, reservation/contact actions; no photos/hours enrichment yet)
- [x] MapView (Google Maps SDK pins — per-type colors, glass header, peek card, tap-triggered user location permission + camera recentering, filter wiring)
- [x] Visited tracking + notes + rating (`markVisitedWithRecord` in AppState; writes Visit row + updates restaurant rating)
- [x] MarkVisitedSheet (star rating, photos, visit note, Save/Skip; auto-shown after "Mark as visited")
- [x] Journal read path (`fetchVisits`, `fetchMedia`, private storage download, grouped summaries in `AppState`)
- [x] JournalIndexView (real data, stats, navigation, empty state)
- [x] JournalLocationView (scrapbook entries, occasion labels, photo thumbnails, empty state, entry deletion with storage cleanup, and move-back-to-wishlist recovery for accidental visits)
- [x] JournalComposeView (editable date, occasion, note, vibe tags, photo/video attachment management)
- [x] JournalViewerView (fullscreen photo/video viewer with swipe paging, captions, thumbnails, and native video playback)
- [x] CrossPostSheet (copy media to another circle, signed-link copy, and native iOS sharing)
- [x] PickerView + MatchView (server-authoritative shared round, real circle-member votes/progress, unanimous matching, undo/rematch, Realtime plus polling recovery, and revision guards; deployed and verified against hosted Scout)
- [x] MediaService (downsampled photo/video thumbnails, shared in-flight loads, advisory memory budget, deletion/sign-out invalidation, original external-share file preparation, and direct camera photo capture)
- [x] Reservation deep links (OpenTable/Resy search links plus Google website/phone actions when available)

### Phase 3 — Polish & Platform
> Native iOS integrations and social import

- [x] Share Extension (Safari + Apple Maps + Google Maps URL/text capture, Apple Maps MapKit place payloads, Google Maps short-link expansion, safer shared-text/link parsing, App Group handoff, main-app import review, Places matching/manual fallback, and wishlist save)
- [x] Social share capture foundation (TikTok/Instagram/source detection, first-pass caption cleanup, and import review handoff)
- [x] Debug-only simulator social import test hook for exercising TikTok-style import review without installing TikTok
- [x] TikTok/Gemini structured parser UI integration (AI-assisted restaurant/city/cuisine/vibe extraction in import review)
- [x] GeminiService (Google Gemini API — structured JSON caption parsing from TikTok/social)
- [x] Gemini cuisine + vibe autofill from restaurant name (AddRestaurantView: automatic fallback for generic Places cuisine, optional manual name/address suggestions, confidence threshold, canonical vibe labels, user-edit protection, cancellation/stale-response guards, and nonblocking manual fallback)
- [x] ScoutWidget (WidgetKit: small/medium active-circle wishlist, shared App Group snapshot, change-driven reloads, sign-out cleanup, 24-hour stale state, and wishlist deep link)
- [x] Siri Shortcuts (App Intents: open active-circle wishlist, shared picker, and journal; foreground/auth-gated navigation with no automatic votes or writes)
- [x] App icon + branding assets (Atlas compass/fork, light/dark/tinted iOS icons, shared vector sign-in/first-circle/loading mark, exact sRGB accent, portable SVG and regeneration guide)
- [x] Circle invitations (member-managed seven-day link/code, hash-only storage, auth-gated preview and explicit join, replacement/revocation, real member snapshots, and shared-picker participant refresh)
- [x] Wishlist loading performance slice (saved rows before Places, three-request concurrency limit, stable fallback/order, edit-safe merges, circle/auth/cancellation guards, and refresh-failure preservation)
- [x] Journal thumbnail performance slice (512px oriented previews, detached decoding, shared downloads, advisory cache budget, cancellation/deletion/sign-out guards, real macOS/iOS codec tests)
- [ ] Remaining performance + polish pass (physical-device profiling, large-journal device walkthrough, and release checks)

Name-based suggestions require `GEMINI_API_KEY` in the ignored `Scout/Config.xcconfig` (existing `GEMINI_MODEL` setting is reused). They fill only empty cuisine and add canonical vibes; specific Places cuisine and user choices take precedence. No key hides the suggestion control. Unknown businesses, low confidence, and API errors leave the form usable, and Save never waits for suggestions. Suggestions apply only in the add form; bulk import and existing saved restaurants are unchanged.

Verification: `Tests/run-metadata-tests.sh` exercises the production service with mocked URLSession responses (request schema/address context, canonical tags, low confidence, generic metadata, missing key, cancellation, HTTP/malformed-response errors, and social-parser regression). The harness needs no API key or Supabase access. UI walkthrough checks are documented in `Tests/README.md`.

---

### Journal thumbnail performance

All journal thumbnail surfaces (index, scrapbook polaroids, viewer strip, and cross-post preview) use one `MediaThumbnailStore` through the existing `AppState.mediaService`. ImageIO creates oriented photo previews with a 512px longest edge instead of retaining full-resolution photos for small views; AVFoundation creates size-limited video posters with preferred track rotation. Downloaded originals are still required, so this improves decoding/cache memory without promising lower network transfer sizes. The fullscreen viewer and external sharing continue using original media.

Decoding and video temporary-file work run in a detached utility task. Duplicate storage-path requests share one download/decode; cancelling a view discards its result while another view can still finish the same load. NSCache uses actual decoded byte costs with a 32MB advisory budget and 128-entry limit; these are eviction hints, not a hard cap on process memory. Deleting media invalidates its cached/in-flight preview. Sign-out clears previews, cancels pending work, and advances a generation so late old-session results cannot repopulate the cache or displace a new request. No new persistent thumbnail cache is added; temporary video files are removed after generation.

`Tests/run-media-thumbnail-tests.sh` exercises production ImageIO/AVFoundation/store code with a 12MP rotated JPEG, small transparent PNG, rotated synthetic video, corrupt input, deferred downloads, cache hits, concurrent callers, retry, and cancellation/clear/delete/replacement races. The same harness runs on iOS Simulator and checks UIKit image wrapping. A signed Simulator app build checks integration. Synthetic codec/cache checks do not replace profiling large journals on a physical device.

---

### Faster wishlist and map loading

`loadRestaurants` now publishes the database result and updates circle counts before Google detail enrichment. The wishlist spinner ends at that point; saved coordinates can draw map pins while current Google details refresh. `RestaurantEnrichment` keeps at most three Places requests per refresh in flight, skips manual places, preserves saved order and data when a detail request fails, and stops scheduling work after cancellation or a scope change. Already-started SDK requests may finish after invalidation; no additional requests are scheduled for that refresh. Google details remain transient in memory; this adds no persistent Places cache or schema change.

Each load captures the user, circle, request identity, and local restaurant revision. An older fetch cannot override a newer request or a confirmed local write. Delayed enrichment merges only unchanged rows, preserving edits, visit status, notes, additions, and deletions. Circle changes clear the old list immediately and invalidate requests, including A → B → A switches; sign-out also invalidates loading. A temporary database refresh failure retains previously loaded rows. The journal's optimistic visit/media reconciliation is unchanged.

`Tests/run-restaurant-loading-tests.sh` compiles the production loading extension, enrichment scheduler, and restaurant model with deferred service fixtures. It verifies first publication before any Places completion, the three-request bound, out-of-order results, fallback/order/counts, concurrent writes, overlapping refresh ownership, failure preservation, user/circle/sign-out isolation, invalidated round trips, cancellation, and stopped scheduling. This measures behavior deterministically rather than claiming a device latency benchmark. The signed Simulator build verifies integration with the actual Supabase/Google SDKs; physical-device profiling remains in the polish checklist.

---

### Circle invitations — behavior and deployment

Migration `20261027042354_circle_invitations.sql` adds one invitation row per circle and the authenticated `scout_circle_invite` / `scout_my_circles` RPCs. The hosted Scout project has this migration deployed. The old `get_my_circles` RPC remains for older binaries; the current app fetches nested member initials/IDs in one circle-list request. Circle visibility in the new RPC requires actual membership.

Any current member can create/replace or revoke the circle's invitation. The server generates a 128-bit random code, stores only its SHA-256 hash, and expires it after seven days. The raw code is returned once and held only by the open invite sheet; reopening requires creating a replacement to share again. Replacement/revocation blocks future joins without removing existing members. Invitations also stop working when their creator is no longer a member. Expected invitation IDs reject stale management actions with HTTP 409.

Recipients open `scout://join?code=...` or paste a code/link into Join a circle. The app must be installed; there is no website/App Store fallback. A signed-out deep link stays in AppState memory through sign-in. The authenticated preview discloses only the invited circle name/ID, expiry, and the caller's membership state; it never joins automatically. Explicit Join writes only `auth.uid()` with an idempotent membership insert, refreshes real circle/member data, and opens the joined wishlist. Circle load request guards reject responses started before a confirmed join; later invitation payloads are not cleared by an earlier join. The RootView incoming-sheet host retains import/password-recovery priority.

The invitation table has RLS, an explicit deny policy, and no client table grants. Public RPCs are security invoker with authenticated-only execution, delegating to checked functions in the non-exposed `scout_private` schema with an empty search path. Management and acceptance serialize on the shared pick circle lock; a joined member invalidates the old picker participant snapshot on its next sync. No token is stored in widget snapshots, App Groups, or UserDefaults. Native Share opens a user-controlled share sheet; Scout does not send messages automatically.

`Tests/run-invitation-tests.sh` applies the production migration with real pgcrypto in isolated PGlite, verifies auth/forged-write isolation, hash-only storage, preview/acceptance, nested memberships, expiry, replacement/revocation, removed creators, stale conflicts, and duplicate acceptance, then decodes its responses with production Swift models. Hosted Auth/PostgREST tests verify independent/concurrent member joins and shared-picker invalidation. A signed iOS 26.4 Simulator walkthrough verified cold invite links across sign-in, preview without membership, explicit joining, restored circle/member avatars after restart, member-created replacement links, native Share preview (no messages sent), revoke/refresh recovery, and revoked/malformed code feedback. All existing regressions passed; disposable hosted fixtures and the QA Simulator were removed afterward. See `Tests/README.md` for the opt-in harness and device walkthrough.

---

### Shared partner matching — deployment and behavior

Scout's hosted project (`vdhhsxgirkjalysejycw`) has the matching migration deployed and verified as of October 26, 2026. For other databases, apply `20261020230236_real_partner_matching.sql`, `20261027011354_optimize_shared_pick_read_policy.sql`, and `20261027011514_fix_shared_pick_stale_round_error.sql` in order. The follow-ups evaluate the session policy identity once per statement and return `PT409` / HTTP 409 for stale-round actions. Do not use `40001` for this application conflict: hosted PostgREST can retry it indefinitely. Without the migrations, the picker fails closed with a sync error.

The `scout_pick` RPC creates/loads one shared round per circle. The first opener's time-of-day determines the restaurant-type filter; the resulting server deck is fixed for everyone. The server uses a UTC calendar day so device time zones cannot split the round. A new UTC day, membership change, or invalidated/visited deck card regenerates the round. Additional wishlist places do not reshuffle an in-progress deck.

All current circle members participate, with a minimum of two. Every participant must vote yes on the same restaurant; a single user's yes cannot declare a match. Progress resumes from saved votes. The first unanimous result is committed under the round lock and cannot be undone; before matching, users can undo their last vote. A rematch is available after a match or after everyone finishes without one, and an expected session ID prevents concurrent rematch retries from creating separate rounds.

Client writes wait for acknowledgement. Realtime session-revision changes trigger refreshes; five-second foreground polling recovers missed events or unavailable Realtime. Observation stops on background/tab exit; circle/sign-out scope guards and monotonic revisions reject stale responses. Legacy `picks` data and local simulated-match caches are ignored by the new flow.

Both new tables have circle-member SELECT policies; client table writes are revoked. The public RPC is security invoker and delegates to a non-exposed `scout_private` function with an empty search path, explicit `auth.uid()`/membership checks, ordered self-votes, and transaction-level per-circle locking. No caller-supplied user ID is accepted. The migration adds `pick_sessions` to `supabase_realtime` when that publication exists.

Validation applies the actual migrations in isolated PGlite Postgres with distinct authenticated identities and RLS/forged-write tests, followed by Swift decoding/projection tests. Hosted verification used three disposable Auth accounts, a dedicated circle, real PostgREST requests, and an authenticated WebSocket: canonical decks, acknowledged votes, undo, persistence, concurrent unanimous matching/rematches, stale HTTP 409 responses, disagreement, outsider isolation, and forged/anonymous write denial passed. Test fixtures were removed afterward. A signed Simulator build passed; physical two-device interaction remains a manual check. The opt-in hosted harness and walkthrough are documented in `Tests/README.md`.

---

### Siri and App Shortcuts behavior and verification

`ScoutShortcuts` publishes “Open my wishlist in Scout,” “Pick a restaurant in Scout,” and “Open my journal in Scout,” plus matching “Show”/“Help me pick” phrases. All three intents foreground the app and resolve the same `AppState` instance registered by `ScoutApp` with `AppDependencyManager`. They select the active circle's existing screens without declaring matches, casting votes, creating restaurants, or returning private restaurant data to Siri. Signed-out launches show the normal auth gate and retain the requested tab for after sign-in; circles continue using the existing restore flow.

Wishlist navigation selects want-to-try, clears filters, and returns to the list root (including the existing widget link). Journal navigation returns to its index even from a pushed scrapbook screen. Picker/journal navigation preserves wishlist filters. `scout://pick` and `scout://journal` use the same typed routing; password-reset and import-pending links keep their existing handlers. No new Siri entitlement, database migration, credential sharing, or extension target is needed.

`Tests/run-shortcut-tests.sh` runs the production intents with a service-free injected state fixture, production navigation extension, filters, and destination models. It checks the three foreground actions, routing, repeated requests, wishlist reset, filter preservation, widget compatibility, and auth/import link isolation. A signed iOS Simulator build and compiled metadata checks verify all three discoverable intents and shortcut tiles. In Apple's Shortcuts app on Simulator, all three actions launched Scout; a cold journal launch retained its destination through real test-account sign-in, the picker opened without votes/matches, and repeated wishlist execution restored want-to-try from Visited. Disposable hosted fixtures were removed afterward. Full Siri speech recognition and physical-device discovery require the walkthrough in `Tests/README.md`.

---

### Atlas app icon and branding assets

The icon extends the approved Atlas `ScoutCompass` in the design mockups: a fork pointing north, compass ring/rays, and inner diamond. `Scripts/generate-brand-assets.swift` generates the 1024px iOS light, dark, and tinted PNGs, a portable `Branding/ScoutCompass.svg`, the `ScoutCompass` vector-template PDF image set, `Branding/Preview.png`, and the asset-catalog AccentColor. Explicit sRGB colors preserve paper `#F7F1E6` and burnt orange `#CC5500`. Light is opaque, dark has a transparent background for the system surface, and tinted is opaque grayscale. Source icons have square corners; the OS masks them.

`ScoutBrandMark` replaces the placeholder S on sign-in, first-circle, and auth-loading screens using the same vector shape and Atlas tint. It is decorative to avoid repeating the adjacent accessible Scout heading. Existing typography, spacing, auth behavior, navigation shell, and package dependencies are preserved. Existing unused Mac icon slots remain empty; no Icon Composer/Liquid Glass layers are claimed.

`swift Tests/validate-brand-assets.swift` checks asset dimensions/slots, alpha, exact palette pixels, grayscale tint, and vector configuration. Passing a built Scout.app path also checks its icon declaration and compiled renditions. A signed iOS 26.4 Simulator build passed, with visual checks of sign-in and default/dark/tinted Home Screen icons. The decorative mark is absent from the accessibility tree, leaving the adjacent heading. Existing shortcut/widget regressions verify packaging compatibility; see `Branding/README.md` and `Tests/README.md` for generation and release walkthroughs.

---

### ScoutWidget behavior and verification

The Home Screen widget reads only `scout-widget.json` from `group.com.sakshisangani.Scout`. AppState publishes a bounded projection when auth, active circle, or restaurant data changes and requests a WidgetKit timeline reload. Only unvisited restaurants in the active circle are included, newest first with a stable ID tie-break; the total count covers the full wishlist while the snapshot stores at most three display rows. Sign-out clears the cache. No Supabase sessions or API keys are shared with the extension.

WidgetKit controls refresh timing. The provider rereads the local cache on its timeline and schedules a stale state at 24 hours; updates from other members appear after the app fetches them. Tapping opens `scout://wishlist`, selects List / want-to-try, and resets filters in the existing shell. The widget does not implement the deferred recipe cooking / Live Activity idea.

`Tests/run-widget-tests.sh` verifies filtering, ordering, counts, cache round trips, updates, circle switches, sign-out removal, malformed/versioned data, unavailable App Groups, expiry, and the URL contract. See `Tests/README.md` for simulator widget walkthroughs. Device distribution requires provisioning the new `com.sakshisangani.Scout.WidgetExtension` bundle identifier with the same App Group as Scout; simulator builds do not verify device provisioning.

---

## Future Add-ons — Ideas Backlog

These are deferred product ideas outside the current restaurant wishlist, picker, and journal scope. They are not part of the active Phase 3 checklist or the next feature to build unless explicitly prioritized.

### Social Recipe Library & Guided Cooking

**Problem:** Recipes saved on Instagram Reels or TikTok get buried and never cooked. Following a video while cooking also requires repeatedly reopening the social app, replaying sections, and unlocking the phone.

**Concept:** Share a recipe video link to Scout, process it into a structured recipe, and save it in a dedicated recipe library. Let the user review the extracted ingredients, quantities, servings, ordered instructions, and step-specific timers, with a link back to the original creator/video.

Potential features:

- [ ] Recipe link import from Instagram Reels and TikTok through Scout's share flow, distinct from restaurant imports.
- [ ] A browsable saved-recipe library so recipes remain easy to find and cook later.
- [ ] Guided cooking in the app, showing the current instruction, progress, and any timer for that step.
- [ ] Apple widgets / Live Activities for the current instruction and active timer, aiming to reduce repeated app opening and phone unlocking while cooking. Explore the appropriate iOS surfaces and interaction limits when this is prioritized.
- [ ] Small reference images or short clips from the source video alongside relevant recipe steps, where source access and media reuse permit.
- [ ] Optional notifications and reminders that help users revisit saved recipes when they are in the mood to cook; timing and preferences should be user-controlled.
- [ ] Dynamic ingredient quantities: scale a recipe from a chosen anchor ingredient amount, such as the weight of protein or pasta available, as well as by servings. Show updated measurements and allow corrections; cooking times and temperatures need separate handling rather than automatic proportional scaling.

Before implementation, decide how recipe videos can be accessed and processed, how uncertain or missing extraction details are reviewed, how recipe storage relates to circles, and which cooking surfaces belong in the first release. Reuse Scout's existing share infrastructure, AppState, and Atlas design system when developing this add-on.

---

## Design File Locations

All mockups are pixel-accurate React/JSX components. Read these when implementing a screen:

| File | Contents |
|------|----------|
| `Scout/designs/Scout-handoff/scout/project/direction-a.jsx` | All primary screens (Wishlist, Detail, Pick, Map) |
| `Scout/designs/Scout-handoff/scout/project/direction-a-circles.jsx` | Circle picker, circle switcher pill |
| `Scout/designs/Scout-handoff/scout/project/direction-a-journal.jsx` | All journal screens + compose + viewer |
| `Scout/designs/Scout-handoff/scout/project/data.jsx` | Mock data shapes + SVG logos |
| `Scout/SPEC.md` | Full technical spec with screen-by-screen layout details |
| `Scout/Scout.md` | Product narrative and visual identity |

---

## Known Issues

No confirmed open bugs.
