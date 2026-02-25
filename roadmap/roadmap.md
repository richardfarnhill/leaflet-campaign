# Leaflet Campaign - Project Roadmap

## Overview

This roadmap outlines the phased development of the Leaflet Campaign tracker system, transforming from a single-file application to a robust, card-based delivery management platform with Supabase backend integration.

**Total Estimated Timeline:** 12-16 weeks  
**Current State:** Single-file HTML application (index.html - 414 lines)  
**Target State:** Multi-file application with Supabase backend, card-based reservation system, and analytics dashboard

---

## Phase Dependencies

```
Phase 1: Core Infrastructure
    |
    +---> Phase 2: Area Management & Data
    |             |
    |             +---> Phase 3: UI/UX
    |                           |
    |                           +---> Phase 4: Analytics & Visualization
    |
    +------------------------------------------+
                                              |
                    Phase 5: Future (Roadmap) |
```

---

## Phase 1: Core Infrastructure

**Objective:** Establish the database foundation and refactor the application into a modular file structure.

### 1.1 Database Schema Updates

**Priority:** Critical (P0)  
**Estimated Effort:** 2-3 hours  
**Dependencies:** None

Run the new Supabase schema to create the updated database structure. This includes replacing legacy tables with new date-decoupled tables.

**Key Changes:**
- Replace `session_log` with `deliveries` table
- Replace `finance_actuals` with `enquiries` and `cases` tables  
- Replace `rescheduled_sessions` with `reservations` table
- Add new tables: `campaign_config`, `team_members`, `target_areas`

**Detailed Schema:** See [`../supabase_schema.sql`](../supabase_schema.sql)

**Tables to Create:**
| Table | Purpose | Complexity |
|-------|---------|------------|
| `campaign_config` | Singleton config for total leaflets, response rates | Low |
| `team_members` | Richard, Josh, Dan, Cahner, Orla | Low |
| `target_areas` | ~1000 door chunks (NOT date-linked) | Medium |
| `reservations` | Who reserved which area + date | Medium |
| `deliveries` | Completion records | Medium |
| `enquiries` | Date-stamped enquiries | Low |
| `cases` | Date-stamped cases | Low |

---

### 1.2 File Restructuring

**Priority:** Critical (P0)  
**Estimated Effort:** 4-6 hours  
**Dependencies:** 1.1 Database Schema Updates

Split the monolithic index.html into three separate files for better maintainability.

**Current Structure:**
```
leaflet-campaign/
└── index.html   (414 lines - HTML + CSS + JS)
```

**Target Structure:**
```
leaflet-campaign/
├── index.html              # Main entry point (~80 lines)
├── styles.css              # All styles (~200 lines)
├── app.js                  # All JavaScript (~600 lines)
├── supabase_schema.sql     # Database schema
└── roadmap/
    ├── roadmap.md
    └── GPS_TRACKING_ANALYSIS.md
```

---

### 1.3 Supabase Integration

**Priority:** Critical (P0)  
**Estimated Effort:** 3-4 hours  
**Dependencies:** 1.1 Database Schema Updates, 1.2 File Restructuring

Update the JavaScript to use the new Supabase tables and implement the new date-decoupled workflow.

---

## Phase 2: Area Management & Data

**Objective:** Populate the system with target areas and integrate external data sources for area research.

### 2.1 OS Names API Integration for Street Data

**Priority:** High (P1)  
**Estimated Effort:** 8-12 hours  
**Dependencies:** Phase 1 Complete

**Description:**  
Integrate the OS Names API to obtain accurate street and address data for target areas.

**API Details:**
- **Provider:** Ordnance Survey (OS) Data Hub
- **API:** OS Names API (free tier available)
- **Endpoint:** `https://api.os.uk/search/names/v1`
- **Purpose:** Get accurate street names, postcodes, and address counts
- **Data:** 2.5 million UK places (streets, roads, settlements)

**Implementation Steps:**
1. Register for OS Data Hub account (free)
2. Obtain API key
3. Create data fetch utility in app.js
4. Build area lookup by postcode sector
5. Store street data in `target_areas.streets` array

**Example Query:**
```http
GET https://api.os.uk/search/names/v1/find?q=Dean+Row+Road&key=YOUR_API_KEY
```

**Reference:** [OS Data Hub](https://osdatahub.os.uk/)

---

### 2.2 Demographic Data Integration (Census 2021 Tenure Data)

**Priority:** High (P1)  
**Estimated Effort:** 6-8 hours  
**Dependencies:** 2.1 OS Names API Integration

**Description:**  
Integrate UK Census 2021 tenure data to identify high-value areas based on ownership statistics.

**Data Source:**
- **Provider:** ONS (Office for National Statistics) via Nomis
- **Dataset:** Census 2021 - Tenure (TS054)
- **URL:** https://www.nomisweb.co.uk/datasets/c2021ts054
- **Geography:** LSOA (Lower Super Output Area)
- **Metric:** Percentage of owner-occupied properties

**Why This Matters:**
- Owner-occupied households are more likely to need will writing services
- Areas with 60-80% owner-occupation are priority targets (your "middle England" demographic)
- Avoid >80% (mansions) and <40% (social housing)

**Target Demographic Criteria:**
- Owner-occupied: 60-80%
- Housing: Semi-detached/terraced (not flats)
- Location: Suburban (not rural villages, not urban core)
- Life stage: Young families, approaching/at retirement

**Implementation Steps:**
1. Download Census 2021 tenure data from Nomis
2. Calculate owner-occupation rate per LSOA
3. Map LSOA codes to postcode sectors
4. Add `owner_occupation_rate` field to target areas
5. Store in Supabase `target_areas` table

---

### 2.3 Area Chunking Algorithm

**Priority:** High (P1)  
**Estimated Effort:** 8-10 hours  
**Dependencies:** 2.1 OS Names API Integration, 2.2 Demographic Data Integration

**Description:**  
Develop an algorithm to divide delivery areas into manageable chunks.

**Chunking Strategy:**
- Keep whole streets together (NEVER split a street across chunks)
- No fixed chunk size - natural boundaries take priority
- Target: 800-1200 houses per chunk (adjusted for team size)
- Natural boundaries: main roads, railways, rivers

**Algorithm Requirements:**
1. Input: Postcode sector + street list with house counts
2. Process: Group streets into logical chunks
3. Output: Array of target_area objects

**Chunk Size Guidelines:**
| Team Size | Houses per Session | Recommended Chunk Size |
|-----------|--------------------|-----------------------|
| 1 person | 400-600 | 500-800 |
| 2 persons | 800-1200 | 1000-1200 |

**Data Structure per Chunk:**
```javascript
{
  id: "uuid",
  area_name: "Wilmslow - Dean Row",
  postcode_sector: "SK9 2",
  streets: ["Dean Row Road", "Adlington Road"],
  house_count: 650,
  gps_center: { lat: 53.xx, lng: -2.xx },
  google_maps_link: "https://maps.google.com/...",
  status: "available",
  owner_occupation_rate: 72
}
```

---

### 2.4 Additional Area Research

**Priority:** Medium (P2)  
**Estimated Effort:** 4-6 hours (ongoing)  
**Dependencies:** 2.3 Area Chunking Algorithm

**Description:**  
Research and document additional target areas within 15 miles of WA14.

**Geographic Scope:** 15-mile radius from WA14 (Altrincham)

**Excluded Areas (per requirements):**
- WA14, WA15, M33, Heywood (OL10), Stockport (SK1-SK8 inner)

**Areas Already Targeted:**
| Area | Outcode | Distance from WA14 |
|------|---------|---------------------|
| Wilmslow | SK9 | ~8 miles |
| Handforth | SK9 | ~7 miles |
| Knutsford | WA16 | ~6 miles |
| Lymm | WA13 | ~5 miles |
| Poynton | SK12 | ~9 miles |
| Cheadle Hulme | SK8 | ~8 miles |
| East Didsbury | M20 | ~6 miles |

**New Areas to Research:**
| Area | Outcode | Distance from WA14 | Notes |
|------|---------|---------------------|-------|
| Alderley Edge | SK9 | ~9 miles | Affluent Cheshire |
| Prestbury | SK10 | ~10 miles | Middle Cheshire |
| Bollington | SK10 | ~12 miles | Middle Cheshire |
| Macclesfield | SK11 | ~12 miles | Cheshire |
| Disley | SK12 | ~10 miles | Cheshire |
| Whaley Bridge | SK23 | ~14 miles | Derbyshire |
| Mobberley | WA16 | ~4 miles | Near Knutsford |
| High Legh | WA16 | ~7 miles | Near Lymm |

---

## Phase 3: UI/UX Improvements

**Objective:** Implement the card-based target area interface with reservation and delivery recording functionality.

### 3.1 Card-Based Target Area Interface

**Priority:** Critical (P0)  
**Estimated Effort:** 10-12 hours  
**Dependencies:** Phase 2 (areas populated)

Replace the calendar-based session view with a card-based interface showing all available target areas.

**Card Components:**
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

**Features:**
- Filter by status (available, reserved, completed)
- Sort by postcode, house count, demographic score
- Search by area name or postcode
- Google Maps link for each card
- Pagination (20 cards per page)

---

### 3.2 Reservation System

**Priority:** Critical (P0)  
**Estimated Effort:** 8-10 hours  
**Dependencies:** 3.1 Card-Based Target Area Interface

Allow team members to reserve target area cards for specific delivery dates.

**Reservation Workflow:**
1. User clicks "Reserve" on a card
2. Modal opens with date picker
3. User selects team member(s) from dropdown
4. User selects delivery date
5. System creates reservation record
6. Card status changes to "Reserved"

---

### 3.3 Delivery Recording

**Priority:** Critical (P0)  
**Estimated Effort:** 6-8 hours  
**Dependencies:** 3.2 Reservation System

Record delivery completion with leaflets delivered, team members, and optional notes.

**Status Flow:**
```
Available → Reserved → Completed
```

**Validation:**
- Leaflets delivered must be > 0
- Cannot exceed chunk house count by > 10%
- Must have at least one team member

---

### 3.4 Configuration Panel

**Priority:** High (P1)  
**Estimated Effort:** 4-5 hours  
**Dependencies:** Phase 1 Complete

Admin panel to configure campaign settings and manage team members.

**Configuration Options:**
| Setting | Default | Description |
|---------|---------|-------------|
| Total Leaflets | 30,000 | Campaign target |
| Default Case Value | £294.42 | Average instruction value |
| Response Rate (Conservative) | 0.25% | Low scenario |
| Response Rate (Target) | 0.5% | Expected scenario |
| Response Rate (Optimistic) | 0.75% | High scenario |

**Team Members:**
- Richard
- Josh
- Dan
- Cahner
- Orla (new)

---

## Phase 4: Analytics & Visualization

**Objective:** Provide interactive charts and coverage visualization for campaign performance monitoring.

### 4.1 Interactive Charts

**Priority:** High (P1)  
**Estimated Effort:** 8-10 hours  
**Dependencies:** Phase 3 Complete

Build interactive charts showing deliveries, enquiries, and revenue over time.

**Chart 1: Deliveries Over Time**
- Line chart showing leaflets delivered per day/week
- Cumulative total line overlay
- Target progress line

**Chart 2: Enquiries Over Time**
- Bar chart showing enquiries per week
- Comparison to response rate benchmarks
- Trend line

**Chart 3: Revenue Over Time**
- Area chart showing revenue accumulation
- Case value distribution
- Projected revenue scenarios

**Implementation:**
- Library: Chart.js (lightweight, easy integration)
- Data source: Supabase views

---

### 4.2 Coverage Map

**Priority:** High (P1)  
**Estimated Effort:** 10-12 hours  
**Dependencies:** 4.1 Interactive Charts, Phase 2 Complete

Display coverage visualization on a map based on card data (postcode boundaries).

**Map Features:**
- Display all target areas as polygons/points
- Color-code by status (available/reserved/completed)
- Show postcode sector boundaries
- Highlight areas with high demographic scores

**Technical Implementation:**
- Library: Leaflet.js (already in use)
- Data: Postcode boundaries from OS Code-Point Open
- Note: Uses postcode data, NOT GPS coordinates

---

### 4.3 Response Rate Benchmarks

**Priority:** Medium (P2)  
**Estimated Effort:** 3-4 hours  
**Dependencies:** 4.1 Interactive Charts

Display response rate benchmarks and track actual performance against projections.

**Benchmarks:**
| Scenario | Response Rate | Description |
|----------|---------------|-------------|
| Conservative | 0.25% | Pessimistic estimate |
| Target | 0.5% | Expected performance |
| Optimistic | 0.75% | Best case scenario |

---

## Phase 5: Future Enhancements

**Objective:** Advanced features for GPS tracking and system optimization.

### 5.1 GPS Tracking

**Priority:** Medium (P2) - Future Phase  
**Estimated Effort:** 12-20 hours  
**Dependencies:** Phase 4 Complete

**Detailed Analysis:** See [`GPS_TRACKING_ANALYSIS.md`](GPS_TRACKING_ANALYSIS.md)

**Recommended Approach:**
1. **Phase 5.1a:** GPX file upload (simplest - deliverers record route, upload after)
2. **Phase 5.1b:** Track visualization on map
3. **Phase 5.1c:** Overlap detection using Turf.js

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Run supabase_schema.sql
- [ ] Create styles.css file
- [ ] Create app.js file
- [ ] Refactor index.html
- [ ] Test all functionality
- [ ] Deploy to production

### Phase 2: Area Management & Data
- [ ] Register for OS Data Hub
- [ ] Implement OS Names API integration
- [ ] Download Census 2021 tenure data
- [ ] Populate target_areas table
- [ ] Develop chunking algorithm
- [ ] Research additional areas

### Phase 3: UI/UX
- [ ] Build card-based interface
- [ ] Implement filtering and sorting
- [ ] Create reservation modal
- [ ] Build delivery recording form
- [ ] Create configuration panel
- [ ] Add team member management

### Phase 4: Analytics
- [ ] Integrate Chart.js
- [ ] Build deliveries chart
- [ ] Build enquiries chart
- [ ] Build revenue chart
- [ ] Implement coverage map
- [ ] Add response rate benchmarks

### Phase 5: Future
- [ ] Implement GPX upload (see GPS_TRACKING_ANALYSIS.md)
- [ ] Add track visualization

---

## Resource Links

- **Implementation Plan:** [`../IMPLEMENTATION_PLAN.md`](../IMPLEMENTATION_PLAN.md)
- **Database Schema:** [`../supabase_schema.sql`](../supabase_schema.sql)
- **GPS Tracking Analysis:** [`GPS_TRACKING_ANALYSIS.md`](GPS_TRACKING_ANALYSIS.md)
- **OS Data Hub:** https://osdatahub.os.uk/
- **OS Names API:** https://api.os.uk/search/names/v1
- **ONS Census 2021:** https://www.ons.gov.uk/census
- **Nomis Census Data:** https://www.nomisweb.co.uk/datasets/c2021ts054
- **Chart.js:** https://www.chartjs.org/
- **Leaflet.js:** https://leafletjs.com/
- **Turf.js:** https://turfjs.org/

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | February 2026 | Initial roadmap creation |

---

*This roadmap is a living document and will be updated as the project progresses.*
