# Architecture Patterns: Leaflet Delivery Tracking System

**Domain:** Political/Campaign Leaflet Delivery Tracking with Card-Based Reservations
**Researched:** February 2026
**Project Context:** Adding card-based reservation system to existing single-page HTML/Supabase app

---

## Executive Summary

Leaflet delivery tracking systems for political campaigns follow a well-established pattern: **territory management** paired with **worker assignment** and **completion tracking**. The addition of a card-based reservation system introduces a workflow where teams claim geographic "chunks" (800-1200 doors) before delivery, rather than being assigned sessions by date.

Based on research of commercial canvassing platforms (Knockbase, Ecanvasser, NGP VAN) and academic territory design literature, the recommended architecture separates concerns into **Territory Management**, **Reservation Workflow**, **Delivery Recording**, and **Analytics** layers.

**Key architectural insight:** The existing system tracks sessions by date with embedded session data. The new card-based system should track territories independently of dates, allowing teams to reserve chunks and select their own delivery dates—decoupling "what to deliver" from "when to deliver it."

---

## Component Architecture

### Component Boundaries

The system decomposes into four primary components with clear responsibilities:

| Component | Responsibility | Key Entities |
|-----------|----------------|--------------|
| **Territory Management** | Define, store, and query geographic chunks (target areas) | `target_areas` table |
| **Reservation Workflow** | Manage team claims on territories with date selection | `reservations` table |
| **Delivery Recording** | Record actual delivery completion with metrics | `deliveries` table |
| **Analytics & Display** | Aggregate data, display cards, calculate progress | Frontend-only |

### Communication Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Single HTML)                       │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │   Card View  │  │  Map View     │  │  Analytics Dashboard   │  │
│  │  (Territory  │  │ (OS Names/    │  │  (Progress, Revenue,   │  │
│  │   Selection) │  │  GPS Bounds)  │  │   Projections)        │  │
│  └──────┬───────┘  └───────┬──────┘  └───────────┬────────────┘  │
│         │                  │                      │                │
│         └──────────────────┼──────────────────────┘                │
│                            ▼                                         │
│                 ┌──────────────────────┐                             │
│                 │   State Manager      │                             │
│                 │  (In-Memory Cache)   │                             │
│                 └──────────┬───────────┘                             │
└────────────────────────────┼────────────────────────────────────────┘
                             │ REST API Calls
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      SUPABASE BACKEND                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ Territory Layer │  │  Reservation      │  │  Delivery      │ │
│  │                  │  │    Layer          │  │    Layer       │ │
│  ├──────────────────┤  ├──────────────────┤  ├────────────────┤ │
│  │ target_areas    │  │ reservations     │  │ deliveries     │ │
│  │ - area_name    │  │ - area_id        │  │ - area_id      │ │
│  │ - postcode     │  │ - team_member_1  │  │ - team_members │ │
│  │ - streets[]    │  │ - team_member_2  │  │ - date         │ │
│  │ - house_count  │  │ - delivery_date   │  │ - leaflets     │ │
│  │ - gps_bounds   │  │ - status          │  │ - notes        │ │
│  │ - status       │  │                   │  │                │ │
│  └────────┬────────┘  └────────┬─────────┘  └───────┬────────┘ │
│           │                     │                     │           │
│           └─────────────────────┼─────────────────────┘           │
│                                 ▼                                   │
│                    ┌──────────────────────┐                        │
│                    │    Shared Tables      │                        │
│                    │  team_members         │                        │
│                    │  campaign_config      │                        │
│                    │  enquiries / cases    │                        │
│                    └───────────────────────┘                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Primary Data Paths

**1. Territory Creation Flow (Admin)**
```
Admin Input → target_areas INSERT → Return UUID → Cache in memory
```

**2. Reservation Flow (Team)**
```
Select Available Card → Choose Date → reservations INSERT 
→ Update target_areas.status to 'reserved' → Re-render card view
```

**3. Delivery Completion Flow (Team)**
```
Enter Leaflets Delivered → deliveries INSERT 
→ Update target_areas.status to 'completed' → Update summary stats
```

### State Synchronization

The frontend maintains an in-memory cache refreshed via polling:

| Operation | Trigger | Sync Strategy |
|-----------|---------|---------------|
| Load all | Page load | Promise.all parallel fetch |
| Save reservation | Debounced (800ms) | Upsert to reservations |
| Save delivery | Debounced (800ms) | INSERT to deliveries |
| Refresh | Interval (30s) | Full reload |

### Critical State Dependencies

```
target_areas.status ─────────────────────────┐
    │                                         │
    ├── 'available' ──► Can be reserved       │
    ├── 'reserved' ──► Show reservation info  │
    └── 'completed' ──► Show delivery stats   │
                                                  │
reservations ────────────────────────────────────┤
    │                                            │
    └── 'active' ──► Area is claimed              │
    └── 'cancelled' ──► Area becomes available   │
    └── 'completed' ──► Area shows delivery done │
                                                  │
deliveries ──────────────────────────────────────┘
    │
    └── Aggregated for: total_delivered, progress %, revenue projections
```

---

## Database Schema Architecture

### Entity Relationship Diagram

```
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│ target_areas  │       │ reservations  │       │  deliveries  │
├───────────────┤       ├───────────────┤       ├───────────────┤
│ id (PK)       │◄──────│ target_area_id│       │ id (PK)       │
│ area_name     │       │ (FK)          │       │ target_area_id│
│ postcode      │       │               │       │ (FK)          │
│ streets[]     │       └───────┬───────┘       │               │
│ house_count   │               │               └───────┬───────┘
│ gps_bounds    │               │                       │
│ status        │               │                       │
│               │       ┌───────▼───────┐               │
│               │       │ team_members  │               │
│               │       ├───────────────┤               │
└───────────────┘       │ id (PK)       │               │
                        │ name          │◄──────────────┘
                        │ is_active     │   (team_member_1_id, 
                        └───────────────┘    team_member_2_id)
```

### Indexing Strategy

| Table | Index | Purpose |
|-------|-------|---------|
| target_areas | `idx_status` | Filter available/reserved/completed |
| target_areas | `idx_postcode` | Geographic queries |
| reservations | `idx_delivery_date` | Calendar views |
| reservations | `idx_status` | Active reservation queries |
| deliveries | `idx_delivery_date` | Time-series analytics |

---

## Component Build Order

### Recommended Phase Structure

Based on dependency analysis, the components should be built in this order:

#### Phase 1: Territory Foundation
- `target_areas` table with status field
- Basic CRUD for area creation
- Status transition logic (available → reserved → completed)
- **Why first:** All other components depend on having territories to assign

#### Phase 2: Team & Reservation Core
- `team_members` table (already exists in schema)
- `reservations` table with date selection
- Card selection UI showing available areas
- **Why second:** Reservations depend on both territories and team members

#### Phase 3: Delivery Recording
- `deliveries` table entry creation
- Leaflet count input with validation
- Status auto-update on completion
- **Why third:** Must have reservations to record deliveries against

#### Phase 4: Analytics & Display
- Progress calculations (delivered vs total)
- Card-based UI with status indicators
- Revenue projections from schema views
- **Why fourth:** Depends on all three data layers

#### Phase 5: External Data Integration
- OS Names API integration for street data
- Census 2021 demographic filtering
- GPS bounds visualization
- **Why fifth:** Requires established territory structure

### Dependency Graph

```
target_areas ─────► reservations ─────► deliveries ─────► analytics
     │                                        │
     └────────► team_members ◄───────────────┘
                    │
                    ▼
              campaign_config
```

---

## External Integration Points

### OS Names API (UK Address Data)
- **Purpose:** Populate street lists for target areas
- **Integration:** Server-side proxy recommended to cache responses
- **Data flow:** Postcode → OS Names API → streets[] array

### Census 2021 Demographics
- **Purpose:** Filter areas by demographic criteria (optional layer)
- **Integration:** Join on postcode prefix to census data
- **Note:** This is a filtering layer, not core to the reservation workflow

### Supabase Backend
- **Authentication:** Already handled via password (embedded)
- **Real-time:** Not currently used; polling is sufficient for team size
- **Database:** Already provisioned with the schema above

---

## Anti-Patterns to Avoid

### 1. Coupling Reservations to Sessions
**Bad:** Creating reservations only through pre-defined date sessions (current system pattern)
**Better:** Allow teams to select any date when reserving a territory chunk

### 2. Embedding Geographic Data in UI State
**Bad:** Storing street lists or GPS bounds in JavaScript objects
**Better:** Store in `target_areas` table, fetch as needed

### 3. Monolithic Status Field
**Bad:** Single status field determining everything about an area
**Better:** Separate `target_areas.status` (territory state) from `reservations.status` (claim state) from implicit completion (delivery record exists)

### 4. Tightly Coupling Card View to Map View
**Bad:** Card selection requires map interaction
**Better:** Card view is primary, map is optional enhancement

---

## Scalability Considerations

| Scale | Current (Single Campaign) | Growth (Multiple Campaigns) |
|-------|---------------------------|----------------------------|
| **Territory count** | 20-50 chunks | Per-campaign namespace |
| **Team size** | 5 members | Add campaign_id to reservations |
| **Data volume** | ~20K leaflets | Partition by campaign |
| **Concurrent users** | 2-3 | Consider Row Level Security |

**For single-campaign use (current scope):** Current schema is appropriate. No multi-tenancy needed.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Component boundaries | HIGH | Matches patterns from Knockbase, Ecanvasser, NGP VAN |
| Data flow | HIGH | Follows standard CRUD + aggregation pattern |
| Build order | MEDIUM | Dependency logic sound; actual sequencing depends on sprint velocity |
| Schema adequacy | HIGH | Schema already designed with proper normalization |

---

## References

- NGP VAN Data Model documentation (political campaign CRM)
- Knockbase Territory Management features (commercial canvassing platform)
- Territory design literature: MDPI "Divide and Conquer: Location-Allocation Approach to Sectorization"
- Existing Supabase schema in `.planning/supabase_schema.sql`

---

## Implications for Roadmap

1. **Start with Territory Management** — Cannot reserve or deliver without areas defined
2. **Reservation system is the core differentiator** — This is the new capability being added
3. **Delivery recording mirrors existing pattern** — Reuse session tracking mental model
4. **Analytics is incremental** — Builds on existing summary calculations
5. **External APIs are enhancements** — OS Names and Census are nice-to-have, not blockers

**Suggested phase count:** 4-5 phases based on component dependencies above.
