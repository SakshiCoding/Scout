# Scout — Technical Specification

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI |
| Database | Supabase (Postgres) |
| Auth | Supabase Auth + Sign in with Apple |
| Storage | Supabase Storage (photos/videos) |
| Maps | MapKit |
| Location | CoreLocation |
| Places Data | Apple Places API |
| AI Parsing | Google Gemini API |
| Notifications | UserNotifications |
| Extensions | Share Extension, WidgetKit |

---

## Design

### Color Palette
| Name | Hex |
|---|---|
| Burnt Orange | #CC5500 |
| Orange | #FF6B00 |
| White | #FFFFFF |

---

## Feature List

| Feature | Version |
|---|---|
| Bulk import from notes (paste list) | v1 |
| Manual add restaurant | v1 |
| Tag by cuisine, vibe, price range | v1 |
| Want to try vs visited lists | v1 |
| Auto-sort by distance (CoreLocation) | v1 |
| Filter by distance, cuisine, price | v1 |
| Restaurant info card | v1 |
| Hours + open right now indicator | v1 |
| Rating and price range display | v1 |
| Restaurant photo | v1 |
| Sign in with Apple | v1 |
| Shared list between two accounts | v1 |
| Mark as visited + personal notes | v1 |
| Personal rating per visit | v1 |
| Full map view with pins (MapKit) | v1 |
| Top dishes / menu highlights | v2 |
| Direct reservation link (OpenTable/Resy) | v2 |
| Pick for Us swipe feature | v2 |
| Swipe match reveal screen | v2 |
| Pre-filter before Pick for Us | v2 |
| Visit history timeline | v2 |
| Food photo/video gallery per card | v2 |
| Share from Safari / Apple Maps | v2 |
| TikTok share extension | v3 |
| TikTok caption parsing via Gemini API | v3 |
| TikTok inspo link saved on card | v3 |
| Home screen widget | v3 |
| Siri Shortcut integration | v3 |

---

## Development Phases

### Phase 1 — Foundation
> Goal: core data model, auth, and basic wishlist working end to end

- [ ] Supabase schema (restaurants, visits, media, household_members)
- [ ] Sign in with Apple + Supabase Auth
- [ ] Shared list linking (household_members table)
- [ ] Restaurant model + SupabaseService
- [ ] WishlistView (list UI)
- [ ] AddRestaurantView (manual add)
- [ ] BulkImportView (paste to import)
- [ ] LocationService + distance sorting
- [ ] Basic RestaurantCardView
- [ ] Tag system (cuisine, vibe, price)
- [ ] FilterSheetView

### Phase 2 — Enrichment & Core Features
> Goal: make the app genuinely useful day-to-day

- [ ] PlacesService (Apple Places API integration)
- [ ] Rich info card (hours, open now, dishes, rating, photo)
- [ ] MapView (MapKit pins)
- [ ] Visited tracking + notes + rating
- [ ] VisitTimelineView
- [ ] PickerView (swipe UI)
- [ ] MatchView (reveal screen)
- [ ] MediaService (photo/video capture)
- [ ] MediaGalleryView
- [ ] Reservation deep links (OpenTable/Resy)

### Phase 3 — Polish & Platform
> Goal: native iOS integrations and social import

- [ ] Share Extension (Safari + Apple Maps)
- [ ] TikTok Share Extension
- [ ] GeminiService (Google Gemini API caption parsing)
- [ ] TikTok link stored on card
- [ ] ScoutWidget (WidgetKit)
- [ ] Siri Shortcut
- [ ] App icon + branding assets
- [ ] Performance + polish pass