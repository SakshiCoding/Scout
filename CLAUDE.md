# Scout — Claude Development Guide

Scout is a shared restaurant wishlist iOS app organized around **circles** — named groups (couples, families, roommates, travel crews) each with their own wishlist, map, swipe picker, and photo journal. Built with SwiftUI + Supabase + MapKit + CoreLocation + Apple Places API + Google Gemini API.

---

## Current State

The project is **not** a bare SwiftUI shell anymore. Phase 1 is foundation-complete: SwiftUI app structure, shared state, Supabase integration, authentication, circle switching, wishlist UI, manual restaurant add, bulk import, filters, and Atlas design-system helpers are implemented and working end to end.

| File | Status |
|------|--------|
| `Scout/ScoutApp.swift` | App entry point; creates and injects `AppState` |
| `Scout/AppState/AppState.swift` | Main app state for auth, circles, restaurants, filtering, and services |
| `Scout/Services/SupabaseService.swift` | Supabase client and core circle/restaurant/visit/profile methods; circles/restaurants use RPC functions |
| `Scout/Services/AuthService.swift` | Auth session handling and sign-in flows |
| `Scout/Services/LocationService.swift` | Location permissions and distance sorting |
| `Scout/Theme/AtlasTheme.swift` | Direction A "Atlas" colors, typography, layout constants, and shadows |
| `Scout/Views/Root/RootView.swift` | Auth gate and custom tab shell |
| `Scout/Views/Root/CustomTabBar.swift` | Floating custom tab bar; do not replace with SwiftUI `TabView` |
| `Scout/Views/Wishlist/` | Wishlist, add restaurant, bulk import, filters, and restaurant rows |
| `Scout/Views/Detail/RestaurantDetailView.swift` | Detail screen: hero placeholder, title, stat row, note, vibe tags, edit sheet, mark visited |
| `Scout/Views/Circles/` | Circle switcher pill, picker sheet, and new circle sheet |
| `Scout/Views/Shared/` | Shared small UI components and Atlas icons |
| `Scout/Models/` | Circle, restaurant, visit, and media models |

Supabase Swift is already added through Swift Package Manager. Do not remove or recreate package dependencies unless the task explicitly requires it.

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
| Maps | MapKit |
| Location | CoreLocation |
| Places enrichment | Apple Places API |
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

`profiles` · `circles` · `circle_members` · `restaurants` · `visits` · `media`

The schema lives in `supabase/migrations/`. Current circle and restaurant creation/loading use Supabase RPC functions to avoid client-side RLS timing issues:

- `create_circle`
- `get_my_circles`
- `add_restaurant`
- `get_circle_restaurants`
- helper: `is_circle_member`

---

## UI Screens

Some Phase 1 screens are already implemented or partially implemented. Full specs live in `Scout/SPEC.md`, with pixel-accurate React mockups in the design files listed below. When implementing a screen, compare the relevant SwiftUI files against the spec and extend what exists.

| # | View name | Tab | Status | Purpose |
|---|-----------|-----|--------|---------|
| 1 | `WishlistView` | List | Implemented/active | Home — group's restaurant wishlist sorted by distance |
| 2 | `RestaurantDetailView` | — | Implemented (Phase 2 partial) | Hero placeholder, name, cuisine, price, stats, notes, vibe tags, edit sheet, mark visited |
| 3 | `PickerView` | Pick | Placeholder tab only | Swipe-based matching — both members pick independently, match revealed when both agree |
| 4 | `MapView` | Map | Placeholder tab only | Full-bleed topo map with named pins; bottom peek card |
| 5 | `CirclePickerSheet` | — | Implemented/active | Bottom sheet — switch between circles |
| 6 | `JournalIndexView` | Journal | Placeholder tab only | Table of contents for the circle's visit history |
| 7 | `JournalLocationView` | — | Not yet implemented | Per-restaurant scrapbook with polaroid clusters |
| 8 | `JournalComposeView` | — | Not yet implemented | New journal entry: photos, date, occasion, note, vibe tags |
| 9 | `JournalViewerView` | — | Not yet implemented | Fullscreen photo/video viewer with caption block |
| 10 | `MarkVisitedSheet` | — | Not yet implemented | Auto-prompted after "Mark as visited" — capture media + note while fresh |
| 11 | `CrossPostSheet` | — | Not yet implemented | Share a journal photo/video to another circle or externally |

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
- [x] Sign in/auth foundation + Supabase Auth integration
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

- [ ] PlacesService (Apple Places API)
- [x] RestaurantDetailView — partial (hero placeholder, info, edit, mark visited; no photos/hours/Places enrichment yet)
- [ ] MapView (MapKit pins)
- [ ] Visited tracking + notes + rating
- [ ] MarkVisitedSheet
- [ ] JournalIndexView
- [ ] JournalLocationView
- [ ] JournalComposeView
- [ ] JournalViewerView
- [ ] CrossPostSheet
- [ ] PickerView + MatchView
- [ ] MediaService (photo/video capture)
- [ ] Reservation deep links (OpenTable/Resy)

### Phase 3 — Polish & Platform
> Native iOS integrations and social import

- [ ] Share Extension (Safari + Apple Maps)
- [ ] TikTok Share Extension
- [ ] GeminiService (Google Gemini API — caption parsing)
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
