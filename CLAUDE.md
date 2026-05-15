# Scout — Claude Development Guide

Scout is a shared restaurant wishlist iOS app organized around **circles** — named groups (couples, families, roommates, travel crews) each with their own wishlist, map, swipe picker, and photo journal. Built with SwiftUI + Supabase + MapKit + CoreLocation + Apple Places API + Google Gemini API.

---

## Current State

The project is a bare SwiftUI shell — Xcode's default template only. Nothing is implemented yet.

| File | Status |
|------|--------|
| `Scout/ScoutApp.swift` | Entry point only, no DI or setup |
| `Scout/ContentView.swift` | Placeholder "Hello, arjun!" — replace this |

**No Swift Package dependencies have been added.** No Supabase SDK, no networking libraries, nothing.

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

`circles` · `circle_members` · `restaurants` · `visits` · `media`

---

## UI Screens

All 11 screens are unimplemented. Full specs in `Scout/SPEC.md`. Pixel-accurate React mockups in the design files (see below).

| # | View name | Tab | Purpose |
|---|-----------|-----|---------|
| 1 | `WishlistView` | List | Home — group's restaurant wishlist sorted by distance |
| 2 | `RestaurantDetailView` | — | Full info card: hero photo, hours, stats, journal preview, top dishes |
| 3 | `PickerView` | Pick | Swipe-based matching — both members pick independently, match revealed when both agree |
| 4 | `MapView` | Map | Full-bleed topo map with named pins; bottom peek card |
| 5 | `CirclePickerSheet` | — | Bottom sheet — switch between circles |
| 6 | `JournalIndexView` | Journal | Table of contents for the circle's visit history |
| 7 | `JournalLocationView` | — | Per-restaurant scrapbook with polaroid clusters |
| 8 | `JournalComposeView` | — | New journal entry: photos, date, occasion, note, vibe tags |
| 9 | `JournalViewerView` | — | Fullscreen photo/video viewer with caption block |
| 10 | `MarkVisitedSheet` | — | Auto-prompted after "Mark as visited" — capture media + note while fresh |
| 11 | `CrossPostSheet` | — | Share a journal photo/video to another circle or externally |

### Key layout rules across all screens

- Every screen has a `CircleSwitcherPill` pinned at the top
- Tab bar is a **floating custom component** (not SwiftUI's `TabView`) — 4 tabs: List · Map · Pick · Journal
- Bottom sheets use drag handle + 24pt top radius + `rgba(15,10,5,0.55)` dimmed overlay
- "Glass" variants of the circle pill (on hero photos and map) use `backdrop-filter: blur(10px)` equivalent

---

## Development Phases

### Phase 1 — Foundation
> Core data model, auth, circles, basic wishlist end to end

- [ ] Supabase schema (restaurants, visits, media, circles, circle_members)
- [ ] Sign in with Apple + Supabase Auth
- [ ] Circles data model + circle switching
- [ ] Restaurant model + SupabaseService
- [ ] WishlistView
- [ ] AddRestaurantView (manual add)
- [ ] BulkImportView (paste list to import)
- [ ] LocationService + distance sorting
- [ ] RestaurantCardView
- [ ] Tag system (cuisine, vibe, price)
- [ ] FilterSheetView
- [ ] CirclePickerSheet + CircleSwitcherPill

### Phase 2 — Enrichment & Core Features
> Make the app genuinely useful day-to-day

- [ ] PlacesService (Apple Places API)
- [ ] RestaurantDetailView (hours, open now, dishes, rating, photo)
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
