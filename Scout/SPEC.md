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

## Circles

Scout is organized around **circles** — named groups of people (a couple, a family, roommates, coworkers, a travel crew) each with their own shared wishlist, map, journal, and Pick session. A user can belong to multiple circles and switch between them at any time via the circle pill at the top of every screen.

Each circle has:
- A **name** (e.g., "Morgan & me", "Family", "Roommates")
- An **accent color** that identifies it in the switcher, avatar stack, and journal
- **Members** shown as overlapping avatar initials
- Separate **places**, **visited**, **photos**, and **videos** counts

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
| Circles — multi-group support (couples, family, roommates, etc.) | v1 |
| Shared list per circle | v1 |
| Circle switcher pill (global, top of every screen) | v1 |
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
| Journal — per-circle scrapbook of visits | v2 |
| Journal entry composer (photos, video, note, vibe tags) | v2 |
| Cross-post journal media to another circle | v2 |
| TikTok share extension | v3 |
| TikTok caption parsing via Gemini API | v3 |
| TikTok inspo link saved on card | v3 |
| Home screen widget | v3 |
| Siri Shortcut integration | v3 |

---

## Development Phases

### Phase 1 — Foundation — Complete
> Goal: core data model, auth, circles, and basic wishlist working end to end

- [x] Supabase schema (profiles, restaurants, visits, media, circles, circle_members)
- [x] Sign in/auth foundation + Supabase Auth integration
- [x] Circles data model + circle switching
- [x] Restaurant model + SupabaseService
- [x] WishlistView (list UI)
- [x] AddRestaurantView (manual add)
- [x] BulkImportView (paste to import)
- [x] LocationService + distance sorting foundation
- [x] RestaurantRowView
- [x] Tag system (cuisine, vibe, price)
- [x] FilterSheetView
- [x] CirclePickerSheet + CircleSwitcherPill

Phase 1 verified behavior:

- App restores existing circles after restart.
- Manual restaurant add persists.
- Bulk import persists.
- Wishlist rows appear immediately after add/import and reload after restart.
- Filter apply, reset, and clear work for available metadata.

Backend note: Supabase migrations live in `supabase/migrations/`. Circle and restaurant creation/loading use RPC functions (`create_circle`, `get_my_circles`, `add_restaurant`, `get_circle_restaurants`) plus `is_circle_member` to avoid client-side RLS timing issues.

### Phase 2 — Enrichment & Core Features
> Goal: make the app genuinely useful day-to-day

- [ ] PlacesService (Apple Places API integration)
- [ ] Rich info card (hours, open now, dishes, rating, photo)
- [ ] MapView (MapKit pins)
- [x] Visited tracking + notes + rating
- [x] MarkVisitedSheet (auto-prompt after marking visited)
- [x] JournalIndexView (table of contents per circle)
- [x] JournalLocationView (scrapbook per restaurant)
- [x] JournalComposeView (new entry: photos, video, editable date, occasion, note, vibe tags)
- [x] JournalViewerView (fullscreen photo/video with caption, swipe paging, thumbnails, and native playback)
- [x] Journal media policy repair migration for manually initialized Supabase projects
- [x] Journal visit policy repair migration for persisted entry visibility
- [x] CrossPostSheet (copy media to another circle, signed-link copy, and native iOS sharing)
- [x] Viewer media deletion and cached photo/video thumbnails
- [x] Journal entry deletion with attached storage cleanup
- [ ] PickerView (swipe UI with partner progress)
- [ ] MatchView (reveal screen)
- [x] MediaService foundation (cached photo/video thumbnails and external-share file preparation)
- [x] Direct camera photo capture
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

---

## UI Screens

Global layout: floating pill tab bar (List · Map · Pick · Journal), circle switcher pill pinned to the top of every screen. Tab bar floats 22pt from the bottom on a rounded rect (30pt radius) with shadow.

---

### Tab Bar
Four tabs with line-drawn icons (1.6pt stroke, burnt orange when active, subdued ink otherwise). Active tab has a small burnt orange dot below the icon.

| Tab | Icon | Screen |
|---|---|---|
| List | Bullet list | Wishlist |
| Map | Map pin | Map View |
| Pick | Two overlapping cards | Pick for Us |
| Journal | Open book | Journal Index |

---

### Screen 1 — Wishlist (List Tab)

**Purpose:** Home screen; the group's restaurant wishlist sorted by distance.

**Layout (top → bottom):**
- Circle switcher pill + overflow `···` button
- Accent rule + "[Circle]'s Atlas" kicker
- Large serif heading: "Your *atlas*" (italicized word in burnt orange)
- Subtitle: place count + current neighborhood
- **Want to try / Visited** underline tabs (burnt orange active underline)
- Horizontal filter chip row: All · Walking · $–$$ · Open now · Date (scrollable)
- Restaurant list rows (divided by hairline rules)

**Restaurant row:**
- Serif index numeral (e.g., "01") in burnt orange
- Restaurant name (serif 20pt) + distance in miles (serif, right-aligned)
- Cuisine · Price · Rating (sans 12.5pt, muted)
- Status dot (green = open, orange = closes soon, grey = opens later) + vibe tags
- Thumbnail photo (64×76pt, 10pt radius) on the right

---

### Screen 2 — Restaurant Detail

**Purpose:** Full info card for a saved restaurant.

**Layout (top → bottom):**
- Full-bleed hero photo (340pt tall, no radius)
  - Overlaid top row: back chevron button (frosted glass pill) · circle switcher pill (frosted glass, shows member avatars + name) · heart/save button (burnt orange circle)
  - Photo count badge bottom-right (e.g., "1 / 12")
- Cuisine · Price · Distance kicker (uppercase, muted)
- Serif restaurant name (40pt)
- Status dot + closing time
- **Stats row** (3-column grid, hairline borders top/bottom): Rating · Price tier · Miles away
- **Saved by** card (paper2 background): member avatar + "Saved by [Name] · N days ago" + italic note quote
- **Your journal** section: label + "N visits · N photos" + 4-up photo/video thumbnail grid
- **Top dishes** section: 3-column photo cards with dish names
- **Hours** table: 7-day list, today bolded
- Bottom CTAs: "Mark as visited" (full-width, ink background) + notes icon button

---

### Screen 3 — Pick for Us (Pick Tab)

**Purpose:** Swipe-based feature where circle members independently rate restaurants; matches are revealed when both agree.

**Layout (top → bottom):**
- Circle switcher pill + "Round N of N" counter
- "Pick *for us*" heading (italic in burnt orange) + filter summary (distance, price, open now)
- **Card stack** (3 layered cards with slight rotation):
  - Top card: hero photo (280pt) + restaurant info (cuisine/price/distance kicker, serif name 28pt, rating/walk time/price stats)
  - "♥ Yes" verdict badge peeking from right edge (burnt orange pill, rotated)
- **Swipe actions row:** × skip (56pt circle) · ♥ yes (72pt burnt orange circle, center/primary) · ↺ undo (56pt circle)
- **Partner status bar:** member avatar + "[Name] is also picking · N of N done" + mini progress bar

---

### Screen 4 — Map View (Map Tab)

**Purpose:** Full-bleed map showing all circle pins, filterable.

**Layout:**
- Full-bleed topo-style map (fills screen)
- Floating header: circle switcher pill (glass) + Filters button (glass pill, right)
- Place count + active filter summary chip below header
- **Named pins:** label pill (ink background when featured, paper when normal) + burnt orange dot stem; tapping shows bottom card
- **Bottom peek card** (floats above tab bar): restaurant thumbnail + name, cuisine/price/distance, status dot, arrow CTA → tapping navigates to detail

---

### Screen 5 — Circle Picker (Sheet)

**Purpose:** Switch between circles; opened by tapping the circle pill on any screen.

**Presentation:** Bottom sheet over dimmed background (55% dark overlay).

**Layout:**
- Drag handle
- "Switch circle" kicker + "Whose atlas?" serif heading (30pt) + close button
- **Circle rows:** left accent color stripe · overlapping avatar stack (first avatar in circle accent color) · circle name + accent dot · place/visited/photo counts · checkmark (active) or chevron
- **"Start a new circle"** dashed-border row at bottom with `+` button and hint text ("Coworkers, a travel group, a city crew…")

---

### Screen 6 — Journal Index (Journal Tab)

**Purpose:** Table of contents for the active circle's visit history.

**Layout (top → bottom):**
- Circle switcher pill + "[Circle] · Volume 1" kicker + year
- Serif "Where *we've* been" heading (56pt, italic word in burnt orange)
- Stats row: Places · Photos · Videos · Visits (serif numerals, sans labels)
- "The Index" section header + "Most recent ↓" sort label
- **Location rows** (hairline-divided): serif index numeral · polaroid thumbnail · restaurant name + cuisine/visits · last entry date

**Empty state:** Three blank polaroid illustrations with tape decoration; prompt: "Your atlas starts here." + "Browse your wishlist" CTA button.

---

### Screen 7 — Restaurant Journal / Scrapbook

**Purpose:** Per-restaurant scrapbook of all visits for the active circle. Accessed from the detail card's journal section.

**Layout (top → bottom):**
- Circle switcher pill + back chevron + "Journal" kicker
- Serif restaurant name heading + "N visits · N photos · N videos" stats
- **Visit entries** (dashed hairline dividers):
  - Date: large serif day numeral (burnt orange) + "MON · YEAR" + occasion tag (italic, right)
  - Polaroid photo cluster: 2–3 polaroids with tape decoration, slight random rotation
  - Italic handwritten-style note in quotes
- "New entry" dashed-border row at bottom
- Overflow action: "Move back to wishlist" with destructive confirmation; removes the restaurant's journal entries and attached media before restoring wishlist status

**Empty state (visited but no entries):** Single large blank polaroid with + prompt; "Your first night at [Restaurant]." heading + "Add your first entry" CTA.

---

### Screen 8 — Journal Compose (New Entry)

**Purpose:** Create a journal entry: attach photos/video, set date/occasion, write a note, tag the vibe.

**Layout (top → bottom):**
- Navigation bar: Cancel · "New Entry" (centered, uppercase) · Save (burnt orange)
- Location card: restaurant thumbnail + name + neighborhood (paper2 background, changeable)
- **Date + Occasion** 2-column grid (bordered cells)
- **Photos & video** section: 4-up grid (existing media with × remove button + add tile with `+`)
- **"How was it?"** italic text field (paper2 background, min 140pt tall, burnt orange cursor)
- **Vibe chips** (multi-select): Date night · Group · Solo · Brunch · Patio · Bar seat · Loud · Quiet

---

### Screen 9 — Journal Viewer (Fullscreen Photo/Video)

**Purpose:** Full-screen media viewer for journal photos and videos.

**Presentation:** Dark background (#0E0905).

**Layout:**
- Top bar (floating): close × (frosted glass) · restaurant name + "N of N" page indicator · overflow `···`
- Full-bleed hero media (480pt tall); video shows centered play button + duration badge top-right
- Page indicator dots (active = burnt orange pill, wider)
- Caption block: serif day numeral (burnt orange) + "MON · YEAR" + occasion tag + italic note in quotes
- Bottom thumbnail strip: 3 thumbnails, active framed in burnt orange

---

### Screen 10 — Mark Visited Sheet

**Purpose:** Auto-prompted immediately after tapping "Mark as visited" on the detail screen; captures media and a note while the visit is fresh.

**Presentation:** Bottom sheet over dimmed detail screen.

**Layout:**
- Circle accent dot + "Logged for [Circle]" kicker
- "You went to *[Restaurant]*." heading (italic restaurant name in burnt orange)
- Subtitle: "While it's fresh — drop a photo or two and a quick note."
- 4-up media tray: up to 3 attached photos with × remove + camera add tile
- Italic note field (paper2 background)
- CTAs: "Skip for now" (outlined) · "Save to journal" (ink, primary)

---

### Screen 11 — Cross-post Sheet

**Purpose:** Share a photo or video from one circle's journal into another circle's journal, or externally.

**Presentation:** Bottom sheet over dimmed fullscreen media viewer.

**Layout:**
- Media thumbnail header: small video/photo preview + restaurant name + date + source circle
- **"Add to another circle"** section: list of other circles with checkbox (accent-colored when selected)
- **"Or send somewhere else"** section: icon grid — Messages · Mail · Copy link · More
- Confirm CTA: "Share to [Circle]" (ink background)
