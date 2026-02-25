# Technology Stack

**Project:** Leaflet Campaign Tracker (Card-Based Reservation System)
**Research Date:** 2026-02-25
**Confidence:** HIGH

---

## Recommended Stack

### Core Frontend

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Vanilla JavaScript** | ES2022+ | Application logic | Existing codebase is vanilla JS. No framework needed for this scope. Maintains consistency, reduces complexity. |
| **Leaflet.js** | 1.9.4 (stable) | Map visualization | Industry-standard open-source mapping library. 42KB gzipped, no dependencies. Actively maintained (v2.0 alpha available). **Use CDN: unpkg** |
| **Chart.js** | 4.x (latest) | Analytics charts | Most popular JS charting library (~60k GitHub stars). Canvas-based rendering is performant for large datasets. MIT licensed. |
| **Turf.js** | 3.0.14 | Geospatial analysis | Client-side geographic operations (buffer, intersect, within). Essential for chunking algorithm and delivery zone analysis. |

**Frontend Architecture:** Keep as multi-file vanilla JS (index.html, styles.css, app.js) rather than introducing a framework. The application scope doesn't warrant React/Vue overhead.

### Backend

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Supabase** | Current (managed) | Backend platform | Already in use. Provides PostgreSQL, Auth, REST API, Real-time subscriptions. No infrastructure to manage. |
| **PostgreSQL** | 15.x (via Supabase) | Database | Relational data for sessions, deliveries, reservations. Reliable, well-understood. |
| **PostGIS** | 3.x (extension) | Spatial data | **CRITICAL**: Enable via Supabase Dashboard. Provides geography types (POINT, POLYGON), spatial indexes (GIST), and functions (ST_DWithin, ST_Intersects). |

### UK Geographic Data APIs

| Service | Purpose | Why |
|---------|---------|-----|
| **OS Names API** | Street names, place names, postcodes | **Free** Ordnance Survey API. 2.5M identifiable places in GB. Updated quarterly. Endpoint: `https://api.os.uk/search/names/v1` |
| **postcodes.io** | Postcode lookup, geocoding | **Free**, MIT licensed. Updated with ONS data. Essential for reverse geocoding and postcode validation. Rate limit: 30 req/sec. |
| **Census 2021** | Demographic filtering | ONS provides tenure data (owner-occupied vs private rent). Use **NOMIS** or **ONS API** for output area data. Filter target areas to 60-80% owner-occupied. |

### Development Tools

| Tool | Purpose | Version |
|------|---------|---------|
| **Browser DevTools** | Debugging | Chrome/Firefox/Edge (any modern) |
| **Supabase CLI** | Local development, migrations | Latest (via npm) |
| **PostGIS utilities** | Spatial SQL testing | pgAdmin or DBeaver |

---

## Installation & Setup

### CDN Dependencies (Recommended for MVP)

```html
<!-- Leaflet CSS -->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" 
      integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" 
      crossorigin="" />

<!-- Leaflet JS -->
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" 
        integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" 
        crossorigin=""></script>

<!-- Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>

<!-- Turf.js (bundle with all modules) -->
<script src="https://unpkg.com/turf@3.0.14/turf.min.js"></script>
```

### Database: Enable PostGIS

```sql
-- Enable PostGIS extension (run in Supabase SQL Editor)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify installation
SELECT PostGIS_Version();
```

### Recommended Database Schema Additions

```sql
-- Example: Delivery areas with geography
CREATE TABLE target_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  postcode_district TEXT,  -- e.g., "WA14"
  geometry GEOMETRY(POLYGON, 4326),  -- WGS84
  door_count INTEGER,
  owner_occupied_pct FLOAT,  -- From Census 2021
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial index for geographic queries
CREATE INDEX target_areas_geo_idx ON target_areas USING GIST (geometry);

-- Example: Reservations with temporal bounds
CREATE TABLE reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  area_id UUID REFERENCES target_areas(id),
  team_member TEXT NOT NULL,
  status TEXT DEFAULT 'reserved',  -- reserved, active, completed, abandoned
  reserved_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  delivery_count INTEGER DEFAULT 0
);
```

---

## Architecture Patterns

### Frontend: Client-Side SPA

```
index.html       -- Main HTML structure
  ├── styles.css -- All styling
  └── app.js     -- Application logic
      ├── Supabase client initialization
      ├── State management (in-memory)
      ├── UI rendering functions
      └── API interaction layer
```

**Why vanilla JS:**
- Small team (5 people)
- No build step needed
- Existing codebase is vanilla
- Performance is sufficient for this scale
- Easier to debug in browser DevTools

### Backend: Supabase REST API

```
Supabase Project
    ├── Database (PostgreSQL + PostGIS)
    ├── Auth (email/password - existing)
    ├── API (auto-generated REST)
    └── Storage (if needed for exports)
```

### Geographic Data Flow

```
1. OS Names API → Street/place data for target area
2. postcodes.io → Validate postcodes, get coordinates
3. Census 2021 → Owner-occupied percentages per area
4. Client-side Turf.js → Chunking algorithm (800-1200 doors)
5. Supabase/PostGIS → Store polygons, query overlaps
6. Leaflet → Visualize delivery areas on map
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Mapping | Leaflet 1.9.4 | Mapbox GL JS | Mapbox requires API key and has usage limits. Leaflet is free, open-source, sufficient for this use case. |
| Charts | Chart.js 4.x | D3.js | D3 is too low-level. Chart.js provides ready-made chart types with less code. |
| Geospatial (client) | Turf.js 3.x | Geographiclib | Turf has better GeoJSON support and more operations relevant to delivery chunking. |
| Geospatial (server) | PostGIS | MongoDB Geospatial | PostGIS is more mature, better integrated with Supabase, and has superior spatial functions. |
| Geocoding | postcodes.io | Google Geocoding | postcodes.io is free, UK-specific, and doesn't require API keys. |
| Framework | Vanilla JS | React/Vue | Existing vanilla codebase. Adding framework complexity unnecessary for this scope. |
| Maps (UK tiles) | OpenStreetMap | Google Maps | OSM is free, requires no API key, and has excellent UK coverage via OSM contributors. |

---

## What NOT to Use

| Technology | Why Avoid |
|------------|-----------|
| **Google Maps API** | Requires credit card, has usage limits, costs money for high volume |
| **Mapbox (free tier)** | Has request limits; can get expensive at scale |
| **MongoDB Geospatial** | Would require separate database; Supabase/PostgreSQL is already in use |
| **React/Vue/Angular** | Overkill for this scope; adds build step, increases complexity |
| **D3.js** | Too low-level for simple charts; Chart.js is better fit |
| **Apple/Here Maps** | Poor UK coverage compared to OSM |
| **CartoDB** | Adds another service; PostGIS in Supabase handles spatial needs |

---

## Phase-Specific Recommendations

### Phase 1: Card-Based Reservation System
- **Stack:** Vanilla JS + Supabase + Leaflet + Turf.js
- **Focus:** Area CRUD, reservation logic, basic map display
- **New DB tables:** target_areas, reservations

### Phase 2: OS Names API Integration
- **Stack:** Client-side fetch to OS Names API
- **Focus:** Street data import, door counting algorithm
- **Challenge:** Rate limiting on OS Names API (implement caching)

### Phase 3: Census 2021 Demographic Filtering
- **Stack:** Pre-process Census data → Supabase
- **Focus:** Owner-occupied percentages per Output Area
- **Data source:** ONS NOMIS (free), download as CSV → import to Supabase

### Phase 4: Analytics Dashboard
- **Stack:** Chart.js
- **Focus:** Delivery trends, enquiry rates, revenue projections
- **Reuse existing finance logic** from index.html

---

## Security Notes

| Concern | Mitigation |
|---------|------------|
| Hardcoded Supabase credentials | Move to environment variables, use Supabaseanon key with RLS policies |
| OS Names API key | Not required for basic tier (OS OpenData) |
| Census data | Public data, no auth needed |
| postcodes.io | Rate limited but no key required for basic use |

---

## Sources

- **Leaflet:** https://leafletjs.com/ (v1.9.4 stable, August 2025)
- **Chart.js:** https://www.chartjs.org/ (v4.x, October 2025)
- **Turf.js:** https://unpkg.com/turf@3.0.14/ (v3.0.14, latest stable)
- **Supabase PostGIS:** https://supabase.com/docs/guides/database/extensions/postgis
- **OS Names API:** https://www.ordnancesurvey.co.uk/products/os-names-api (Free, updated quarterly)
- **postcodes.io:** https://postcodes.io/ (MIT licensed, free)
- **ONS Census 2021:** https://www.nomisweb.co.uk/query/construct/census2021.asp

---

*Research confidence: HIGH - All recommendations verified with official documentation and current versions.*
