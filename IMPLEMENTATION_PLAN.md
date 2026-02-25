# Leaflet Campaign - Implementation Plan

## Overview

Refactor from single-file to 3-file structure, implement card-based reservation system with OS Names API integration for street data and Census 2021 demographic filtering.

---

## File Structure

### Current (1 file)
```
leaflet-campaign/
└── index.html   (414 lines - HTML + CSS + JS)
```

### Proposed (3 files + roadmap)
```
leaflet-campaign/
├── index.html              # Main entry point (~80 lines)
├── styles.css              # All styles (~200 lines)
├── app.js                  # All JavaScript (~600 lines)
├── supabase_schema.sql     # Database schema
├── IMPLEMENTATION_PLAN.md   # This file
└── roadmap/
    ├── roadmap.md          # Phased project roadmap
    └── GPS_TRACKING_ANALYSIS.md  # Future phase analysis
```

---

## Data Sources

| Source | Purpose | Access |
|--------|---------|--------|
| **OS Names API** | Street names, place data | Free - https://api.os.uk/search/names/v1 |
| **Census 2021 Tenure** | Owner-occupied % by LSOA | Free - Nomis |
| **postcodes.io** | Postcode geocoding | Free - no API key |

---

## Database Changes

### New Tables
| Table | Purpose |
|-------|---------|
| `campaign_config` | Total leaflets (~30k), response rates |
| `team_members` | Richard, Josh, Dan, Cahner, Orla |
| `target_areas` | Delivery chunks (NOT date-linked) |
| `reservations` | Who reserved which area + date |
| `deliveries` | Completion records |
| `enquiries` | Date-stamped enquiries |
| `cases` | Date-stamped cases |

### Deprecated Tables
- `session_log` (replaced by deliveries)
- `finance_actuals` (replaced by enquiries + cases)
- `rescheduled_sessions` (replaced by reservations)

---

## Target Areas

### Geographic Scope
- **Radius:** 15 miles from WA14 (Altrincham)
- **Excluded:** WA14, WA15, M33, Heywood (OL10), Stockport (SK1-SK8 inner)

### Currently Targeted Areas
| Area | Outcode | Distance from WA14 |
|------|---------|---------------------|
| Wilmslow | SK9 | ~8 miles |
| Handforth | SK9 | ~7 miles |
| Knutsford | WA16 | ~6 miles |
| Lymm | WA13 | ~5 miles |
| Poynton | SK12 | ~9 miles |
| Cheadle Hulme | SK8 | ~8 miles |
| East Didsbury | M20 | ~6 miles |

### Additional Areas to Research
| Area | Outcode | Distance from WA14 |
|------|---------|---------------------|
| Alderley Edge | SK9 | ~9 miles |
| Prestbury | SK10 | ~10 miles |
| Bollington | SK10 | ~12 miles |
| Macclesfield | SK11 | ~12 miles |
| Disley | SK12 | ~10 miles |
| Whaley Bridge | SK23 | ~14 miles |
| Mobberley | WA16 | ~4 miles |
| High Legh | WA16 | ~7 miles |

---

## Demographic Criteria

Target areas matching your ideal customer profile:

- **Owner-occupied:** 60-80% (avoid >80% mansions, avoid <40% social housing)
- **Housing type:** Semi-detached/terraced (not flats)
- **Location:** Suburban (not rural villages, not urban core)
- **Life stage:** Young families, approaching/at retirement

---

## New Workflow

### Before (Date-Coupled)
1. Calendar shows dates with pre-assigned areas
2. Teams go out on scheduled dates
3. Record delivery after the fact

### After (Date-Decoupled)
1. View all available target area cards
2. Each card shows: area name, postcode, streets, house count, Google Maps link, owner-occupation rate
3. "Reserve" a card for a specific date
4. After delivery, record: date delivered, leaflets, team members
5. Card status changes: available → reserved → completed

---

## Chunking Strategy

**Principle:** Keep whole streets together - NEVER split a street across chunks

1. Get all streets in area (via OS Names API)
2. Group by natural boundaries (main roads, railways)
3. Estimate door count per street
4. Create chunks of ~800-1200 doors (adjusted for team size)
5. NEVER split a street across chunks

---

## UI Changes

### New Features
1. **Campaign Config Panel** - Edit total leaflets, team members
2. **Target Area Cards** - Display as cards with streets, house count, map link
3. **Reservation Modal** - Select team + date for a card
4. **Delivery Form** - Record completion with leaflets + notes
5. **Analytics Dashboard** - Charts for deliveries/enquiries/revenue over time

### Card Display
```
┌─────────────────────────────────────────────┐
│  Wilmslow - Dean Row                        │
│  SK9 2BY                                    │
├─────────────────────────────────────────────┤
│  Streets: Dean Row Road, Adlington Road...  │
│  Houses: 650                                │
│  Owner-occupation: 72%                       │
├─────────────────────────────────────────────┤
│  [View on Google Maps]  Status: Available   │
└─────────────────────────────────────────────┘
```

### Analytics
- Leaflets delivered over time (line chart)
- Enquiries over time (line chart)  
- Revenue over time (line chart)
- Response rate scenarios: 0.25%, 0.5%, 0.75%

---

## Team Members
- Richard
- Josh
- Dan
- Cahner
- Orla (new)

---

## Response Rate Benchmarks
- Conservative: 0.25%
- Target: 0.5%
- Optimistic: 0.75%

---

## Coverage Map

Based on recorded deliveries (NO GPS tracking):

1. Each completed card has postcode sector data
2. Plot completed areas on Leaflet map using postcode centroids
3. Visual indication of coverage (color-coded by status)
4. No overlap detection needed - cards are non-overlapping by design

---

## GPS Tracking (Future Phase)

See [`roadmap/GPS_TRACKING_ANALYSIS.md`](roadmap/GPS_TRACKING_ANALYSIS.md)

Simplest approach for future: GPX file upload after delivery

---

## Implementation Phases

See [`roadmap/roadmap.md`](roadmap/roadmap.md) for detailed phased implementation plan.

### Quick Summary:
1. **Phase 1:** Database schema + file restructuring
2. **Phase 2:** OS Names API + Census data integration + chunking algorithm
3. **Phase 3:** Card-based UI + reservation system + delivery recording
4. **Phase 4:** Analytics charts + coverage map
5. **Phase 5:** Future enhancements (GPS tracking)

---

## External Dependencies

- **OS Data Hub:** https://osdatahub.os.uk/ (free registration)
- **OS Names API:** https://api.os.uk/search/names/v1
- **Census 2021:** https://www.nomisweb.co.uk/datasets/c2021ts054
- **postcodes.io:** https://api.postcodes.io/
