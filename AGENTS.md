# Scout — Codex Development Guide

> **Standing rule:** After implementing any feature, always update CLAUDE.md and AGENTS.md to reflect what was built — file table, UI screens table, Phase checklist. This is automatic, not optional, and does not need to be prompted by the user each time.

Scout is a shared restaurant wishlist iOS app organized around **circles** — named groups (couples, families, roommates, travel crews) each with their own wishlist, map, swipe picker, and photo journal. Built with SwiftUI + Supabase + Google Maps SDK for iOS + CoreLocation + Google Places SDK for iOS + Google Gemini API.

---

## Current State

The project is **not** a bare SwiftUI shell anymore. Phase 1 is foundation-complete. Phase 2 now includes Places enrichment, the map, visited logging, and the first journal slice. Phase 3 has started with the Safari/Apple Maps share-import backbone: SwiftUI app structure, shared state, Supabase integration, authentication, circle switching, wishlist UI, manual restaurant add, bulk import, filters, Atlas design-system helpers, visit records, journal loading, journal browsing, share capture, and import review are implemented.

| File | Status |
|------|--------|
| `Scout/ScoutApp.swift` | App entry point; creates and injects `AppState` |
| `Scout/AppState/AppState.swift` | Main app state for auth, circles, restaurants, filtering, visits, media, journal summaries, services, Google Place detail refreshes, and pick match persistence (`activePickMatch`, `savePickMatch`, `clearPickMatch`, `restorePickMatch`) |
| `Scout/Services/SupabaseService.swift` | Supabase client and core circle/restaurant/visit/media/profile/pick methods; persists Google Place IDs, includes journal reads, private storage downloads, and direct picks table access (`savePick`, `fetchTodayPick`) |
| `Scout/Services/AuthService.swift` | Auth session handling, email/Apple sign-in, password-reset email requests, recovery callback sessions, and password updates |
| `Scout/Services/LocationService.swift` | Location permissions, tap-triggered current-location requests, immediate post-authorization location refresh, and distance sorting |
| `Scout/Services/PlacesService.swift` | Google Places Text Search (New) with Apple local-search fallback; returns Scout-owned place results, enrichment hints (expanded cuisine mapping: 25 types including Seafood, Steakhouse, BBQ, Spanish, Middle Eastern, Brazilian, Indonesian, Lebanese, Turkish; vibe hints from fine dining, fast food, brunch, sports bar types), and Google website/phone contact details |
| `Scout/Services/GoogleMapsConfiguration.swift` | Configures Google Maps SDK from the shared Maps Platform API key |
| `Scout/Theme/AtlasTheme.swift` | Direction A "Atlas" colors, typography, layout constants, and shadows |
| `Scout/Models/SharedRestaurantImport.swift` | Shared app/extension import payload + App Group storage for pending restaurant shares |
| `Scout/Views/Root/RootView.swift` | Auth gate and custom tab shell |
| `Scout/Views/Root/CustomTabBar.swift` | Floating custom tab bar; do not replace with SwiftUI `TabView` |
| `Scout/Views/Auth/SignInView.swift` | Apple/email authentication with friendly error mapping and password-reset email action |
| `Scout/Views/Auth/ResetPasswordView.swift` | Recovery-link destination for choosing and saving a new password |
| `Scout/Views/Wishlist/` | Wishlist, add restaurant, bulk import, filters, and restaurant rows |
| `Scout/Views/Import/ImportReviewView.swift` | Main-app import review sheet for shared Safari/Apple Maps places: circle selection, Places match suggestions, note, and save |
| `Scout/Views/Detail/RestaurantDetailView.swift` | Detail screen: hero placeholder, title, stat row, note, vibe tags, edit sheet, mark visited button, visited-journal shortcut, and reservation/contact actions |
| `Scout/Views/Detail/MarkVisitedSheet.swift` | Lightweight post-visit bottom sheet: circle kicker, restaurant heading, 1–5 star rating, photo picker, italic note field, Save/Skip CTAs |
| `Scout/Views/Map/MapView.swift` | Google Maps SDK map wrapper, custom Atlas markers, camera controls, filters, user-location permission trigger, and restaurant peek card |
| `Scout/Views/Journal/` | Journal index, per-restaurant scrapbook, full composer, fullscreen viewer, and cross-post sheet with real visit/media loading, cached photo/video thumbnails, editable metadata, attachments, swipe paging, video playback, sharing, deletion, and moving accidentally visited places back to the wishlist |
| `Scout/Views/Pick/PickerView.swift` | Swipe pick tab: `PickSession` value-type model, deterministic seed (circleId + date + time-of-day → DJB2 + xorshift64) ensures all circle members see the same 3 restaurants; time-of-day filtering via `establishmentType`; drag gesture with YES/Skip SF-Symbol badges, action buttons (skip/yes/undo), partner status bar, complete/empty states, persistent post-match state with rematch button |
| `Scout/Views/Pick/MatchView.swift` | Match reveal screen: animated heading + restaurant card + member avatars + "Let's go!" (`onConfirm`) / "Pick again" (`onPickAgain`) two-callback CTAs |
| `Scout/Views/Circles/` | Circle switcher pill, picker sheet, and new circle sheet |
| `Scout/Views/Shared/` | Shared small UI components and Atlas icons |
| `ScoutShareExtension/` | Share Extension target: captures URL/text from Safari and Apple Maps, parses place hints, writes a pending import through the App Group, and opens Scout |
| `Scout/Models/` | Circle, restaurant, visit, and media models |

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

`profiles` · `circles` · `circle_members` · `restaurants` · `visits` · `media` · `picks`

The schema lives in `supabase/migrations/`. Current circle and restaurant creation/loading use Supabase RPC functions to avoid client-side RLS timing issues:

- `create_circle`
- `get_my_circles`
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
| 1 | `WishlistView` | List | Implemented/active | Home — group's restaurant wishlist sorted by distance; add flow uses Google Places search and persists Place IDs when configured |
| 2 | `RestaurantDetailView` | — | Implemented (Phase 2 partial) | Hero placeholder, name, cuisine, price, stats, notes, vibe tags, edit sheet, mark visited, visited-journal shortcut, OpenTable/Resy search links, and Google website/phone actions when available |
| 3 | `PickerView` + `MatchView` | Pick | Implemented (Phase 2) | Swipe-based pick: `PickSession` draws a deterministic deck of 3 restaurants (seeded by circleId + calendar date + time-of-day so all circle members see the same set); time-of-day filtering via `establishmentType` (morning/lunch/dinner windows); SF-Symbol heart badge on yes button; simulated partner progress; on mutual match `MatchView` animates in; post-match: Pick tab shows matched restaurant persistently with a shuffle rematch button top-trailing; match saved to Supabase `picks` table (one per circle per day) + UserDefaults offline cache; `MatchView` has `onConfirm`/`onPickAgain` callbacks |
| 4 | `MapView` | Map | Implemented | Full-bleed Google map with custom Atlas pins, glass header, bottom peek card, tap-triggered user location, and filter wiring |
| 5 | `CirclePickerSheet` | — | Implemented/active | Bottom sheet — switch between circles |
| 6 | `JournalIndexView` | Journal | Implemented/active | Table of contents for visited restaurants, enriched with real visit/media stats, recent-first rows, circle switching, and blank-polaroid empty state |
| 7 | `JournalLocationView` | — | Implemented | Per-restaurant scrapbook with visit dates, occasion labels, photo polaroid clusters, notes, empty state, compose action, destructive entry deletion, and moving a place back to the wishlist |
| 8 | `JournalComposeView` | — | Implemented | Full-screen new entry flow: editable date, occasion, note, vibe chips, removable photo/video attachments, and save |
| 9 | `JournalViewerView` | — | Implemented | Fullscreen dark photo/video viewer with swipe paging, page dots, caption block, cached thumbnail strip, close/share/overflow controls, deletion, and native video playback |
| 10 | `MarkVisitedSheet` | — | Implemented | Auto-prompted after "Mark as visited" — rating, photos, and visit note; "Save to journal" creates a Visit record and uploads photos, "Skip for now" marks visited only |
| 11 | `CrossPostSheet` | — | Implemented | Copy a journal photo/video into another circle's matching restaurant journal or share externally through iOS |
| 12 | `ImportReviewView` | — | Implemented | Main-app review sheet launched from the Share Extension; confirms Safari/Apple Maps imports, chooses circle, matches Google/Apple Places results, and saves to wishlist |
| 13 | `ResetPasswordView` | — | Implemented | Full-screen password recovery form opened by Supabase email links through `scout://password-reset` |

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
- [x] PickerView + MatchView (local session, simulated partner; match result persisted to Supabase `picks` table + UserDefaults cache; real-time partner sync deferred to future phase)
- [x] MediaService (cached photo/video thumbnails, external-share file preparation, and direct camera photo capture)
- [x] Reservation deep links (OpenTable/Resy search links plus Google website/phone actions when available)

### Phase 3 — Polish & Platform
> Native iOS integrations and social import

- [x] Share Extension (Safari + Apple Maps URL/text capture, App Group handoff, main-app import review, Places matching, and wishlist save)
- [ ] TikTok Share Extension
- [ ] GeminiService (Google Gemini API — caption parsing from TikTok/social)
- [ ] Gemini cuisine + vibe autofill from restaurant name (when Google Places types are too generic)
- [ ] ScoutWidget (WidgetKit)
- [ ] Siri Shortcut
- [ ] App icon + branding assets
- [ ] Performance + polish pass

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
