# Route Planning Engine — Technical Design

**Project:** Leaflet Campaign Tracker
**Version:** 1.0
**Last updated:** 2026-02-25
**Status:** Designed, pending implementation (Phase 6 T8)

---

## Overview

The Route Planning Engine generates a campaign's delivery routes from a natural-language area
description. It resolves the area to constituent postcode sectors, filters by demographic
criteria (owner-occupied tenure), excludes restricted areas by radius, chunks the remaining
sectors into 800-1200 door delivery routes, and presents a plan for the user to approve and
instantiate into the database.

---

## Data Sources

All sources are free, require no API key, and support browser-side `fetch()` (CORS verified).

### 1. postcodes.io — Place Resolution & Postcode Lookup

**Base URL:** `https://api.postcodes.io`

| Endpoint | Use | Example |
|----------|-----|---------|
| `GET /places?q={name}&limit=20` | Resolve place name to candidate places with outcode | `/places?q=Preston&limit=20` |
| `GET /postcodes?q={sector}&limit=100` | Get all unit postcodes in a sector | `/postcodes?q=SK44&limit=100` |
| `GET /postcodes/{postcode}` | Single postcode lookup → lat/lng, OA21 code | `/postcodes/SK44AA` |

**Key fields returned per postcode:**
- `latitude`, `longitude` — for map display and exclusion radius checks
- `oa21` — 2021 Output Area code (e.g. `E00060274`) — links to NOMIS tenure data
- `outcode`, `incode` — for sector grouping
- `admin_district` — town/borough name for route labelling

**Place disambiguation:** `/places` returns `outcode`, `county_unitary`, `region`, `country` —
sufficient to show the user a picker when multiple places share a name (e.g. Preston PR vs Preston LA).

**Rate limit:** 30 req/sec. No key needed.

---

### 2. NOMIS API — Census 2021 Tenure (Owner-Occupied %)

**Base URL:** `https://www.nomisweb.co.uk/api/v01`
**CORS:** `Access-Control-Allow-Origin: *` — confirmed browser-callable
**Key required:** No

**Dataset:** `NM_2072_1` — Census 2021 Table TS054: Tenure
**Geography type:** `TYPE150` = 2021 Output Areas (OA21)

**Query format:**
```
GET /dataset/NM_2072_1.data.json
  ?geography={oa21_numeric_id}
  &measures=20301
  &select=geography_code,c2021_tenure_6_name,obs_value
```

Where `{oa21_numeric_id}` is the numeric NOMIS internal ID for the OA.

**Getting the NOMIS numeric ID from an OA21 code (e.g. E00060274):**
```
GET /dataset/NM_2072_1/geography/{oa21_code}.def.sdmx.json
```
Returns the numeric value used in data queries.

**Alternative — bulk query for a district:**
```
GET /dataset/NM_2072_1.data.json
  ?geography=TYPE150
  &geography_filter=oa21_code
  &measures=20301
```
(Batch by district LAD code to avoid rate limits.)

**Tenure categories in response:**
- `Owned outright` — percentage
- `Owned with mortgage/loan` — percentage
- `Shared ownership` — percentage
- `Social rented (all)` — percentage
- `Private rented (all)` — percentage

**Target filter:** owner-occupied % ≥ 60% (i.e. `Owned outright` + `Owned with mortgage` ≥ 60%)

**Rate limit:** Not documented; use batching and cache results client-side per session.

---

### 3. Household / Door Count

**Method:** ONS standard — a 2021 Output Area contains **approximately 125 households** on average
(Census design target: 100-625, mean ~125 for residential OAs).

For more precise counts, query NOMIS `NM_2001_1` (TS001 - Usual residents / households):
```
GET /dataset/NM_2001_1.data.json?geography={oa21_numeric_id}&measures=20100
```

**House count per route = sum of household counts across all OAs in that route.**
This is what populates `target_areas.house_count` — the number the user sees on the card.

---

### 4. Turf.js — Geospatial Operations

Already on stack (CDN: `https://unpkg.com/turf@3.0.14/turf.min.js`)

Used for:
- **Exclusion radius check:** `turf.distance(point, restrictedCentre, {units:'miles'}) < radius`
- **Route chunking:** Cluster OA centroids into groups of 800-1200 doors using proximity
- **Contiguity:** Keep geographically adjacent OAs together in the same route

---

## Demographic Filter

**Target profile:** 60-80% owner-occupied (homeowners — wills/probate demographic)
**Exclusion:** Areas below 60% owner-occupied (high social housing = not target market)
**Soft ceiling:** Areas above 80% owner-occupied are fine to include (wealthy homeowners are valid)

**Filter applied at OA level:** Each OA gets a tenure score from NOMIS. OAs below threshold
are excluded before chunking.

**Demographic Learning Stub:**
When an enquiry is recorded as `instructed = true`, the system records the OA21 code and
its demographic profile to the `demographic_feedback` table. This builds a dataset for
future model refinement (e.g. "areas with 70-75% owner-occupied convert at 0.8% vs 0.4%
in 60-65% areas"). A later phase will import Richard's existing client spreadsheet to
pre-populate this table.

---

## Restricted Areas

### Global Exclusions (hardcoded in DB, `campaign_id = NULL`)

These never change — they represent WillSolicitor offices and competitors' territory:

| Postcode | Location | Radius |
|----------|----------|--------|
| WA14 1QP | Altrincham (own office) | 2 miles |
| SK4 4QG | Stockport area | 2 miles |
| SK4 4DT | Stockport area | 2 miles |
| OL10 4NN | Heywood | 2 miles |

**Rule:** Any OA whose centroid falls within the exclusion radius of any global restricted
postcode is excluded from route generation.

### Campaign-Specific Exclusions (`campaign_id` set)

Managed per-campaign via the config modal. Examples: competitor solicitors, areas already
covered by another campaign, client-requested exclusions.

### DB Schema Change Required

```sql
ALTER TABLE restricted_areas
  ADD COLUMN campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE;
-- NULL = global, set = campaign-specific
```

The map fetch changes to:
```
/rest/v1/restricted_areas?or=(campaign_id.is.null,campaign_id.eq.{currentCampaignId})
```

---

## Database Schema

### New Table: `route_postcodes`

```sql
CREATE TABLE route_postcodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_area_id UUID NOT NULL REFERENCES target_areas(id) ON DELETE CASCADE,
  postcode TEXT NOT NULL,           -- Full unit postcode e.g. "SK4 4AA"
  postcode_sector TEXT,             -- Sector e.g. "SK4 4"
  outcode TEXT,                     -- Outcode e.g. "SK4"
  oa21_code TEXT,                   -- ONS OA21 code e.g. "E00060274"
  lat NUMERIC,
  lng NUMERIC,
  owner_occupied_pct NUMERIC,       -- From NOMIS at time of route creation
  household_count INTEGER           -- From NOMIS at time of route creation
);

CREATE INDEX route_postcodes_area_idx ON route_postcodes(target_area_id);
CREATE INDEX route_postcodes_sector_idx ON route_postcodes(postcode_sector);
CREATE INDEX route_postcodes_oa21_idx ON route_postcodes(oa21_code);
```

**Why this table matters:**
- **Enquiry matching:** When an enquiry's postcode is recorded, look up `route_postcodes`
  to find which `target_area_id` it belongs to — auto-populate the route field
- **Heatmap:** Colour individual postcode sectors on the map (not just the representative postcode)
- **Analytics:** Correlate delivery coverage with enquiry density at sector level
- **Demographic feedback:** Join on `oa21_code` to enrich feedback data

### New Table: `demographic_feedback`

```sql
CREATE TABLE demographic_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  enquiry_id UUID REFERENCES enquiries(id) ON DELETE CASCADE,
  oa21_code TEXT NOT NULL,
  owner_occupied_pct NUMERIC,
  instructed BOOLEAN DEFAULT false,
  instruction_value NUMERIC,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## UX Flow

### Step 1 — Area Input
User clicks **"Plan Routes"** button (visible when a specific campaign is selected).
Free-text field: *"Describe the target area — e.g. 'West Yorkshire', 'Preston', 'SK9 postcode district', 'Wilmslow'"*

### Step 2 — Disambiguation (if needed)
`postcodes.io /places` returns multiple matches → show picker:
```
"Preston" matches:
  ○ Preston, Lancashire (PR1, PR2, PR3) — North West
  ○ Preston, East Lothian (EH40) — Scotland
  ○ Preston, Wiltshire — South West
```
User selects. The selection gives us the outcode(s) to process.

### Step 3 — Confirm Parameters
Pre-filled form, all editable:
- **Demographic filter:** Owner-occupied ≥ [60]% ✓
- **Route size:** [800] – [1200] doors
- **Leaflet budget:** pulled from `campaign.target_leaflets`
- **Campaign-specific exclusions:** list (add/remove inline)
- **Global exclusions:** shown read-only (WA14 1QP etc.)

### Step 4 — Generate Plan
User clicks **"Generate Plan"**. Progress indicator shown while API calls run.

The engine:
1. Resolves outcodes → sectors (all unit postcodes via postcodes.io)
2. Groups postcodes by OA21 code (deduplicates)
3. Fetches NOMIS tenure for each unique OA (batched, cached)
4. Filters out OAs below owner-occupied threshold
5. Checks each OA centroid against all exclusion radii (Turf.js)
6. Clusters remaining OAs into routes of 800-1200 doors (proximity grouping)
7. Names each route: `{admin_district} {N}` (e.g. "Didsbury 1", "Didsbury 2")

### Step 5 — Review Plan
Plan table displayed:

| # | Route Name | Town | Sectors | Doors | Owner-Occ% | Include? |
|---|---|---|---|---|---|---|
| 1 | Didsbury North | Manchester | M20 2, M20 3 | 947 | 71% | ✓ |
| 2 | Didsbury South | Manchester | M20 5, M20 6 | 1,031 | 68% | ✓ |
| 3 | Heaton Moor | Stockport | SK4 3, SK4 4 | 892 | 73% | ✓ |

User toggles rows in/out. Total door count shown vs leaflet budget.

"Want to tweak the plan? Ask me here" — text input that routes back to conversation (you,
the user, describe changes; Claude updates the plan interactively).

### Step 6 — Instantiate
User clicks **"Create {N} routes"**.

For each selected route:
1. `POST /rest/v1/target_areas` → creates the route card
2. `POST /rest/v1/route_postcodes` (bulk) → stores all constituent postcodes + OA data

Routes appear immediately in the cards grid and on the map.

---

## Enquiry Auto-Matching Logic (downstream — Phase 7)

When an enquiry is saved with a postcode:
1. Normalise postcode (strip spaces, uppercase)
2. Look up in `route_postcodes WHERE postcode = {enquiry_postcode} AND target_area_id IN (routes for currentCampaignId)`
3. If match found → auto-populate `enquiries.target_area_id`
4. If no match → check sector (first 5 chars) in `route_postcodes.postcode_sector`
5. If still no match → leave as "Route unknown"

This is why storing full unit postcodes in `route_postcodes` is critical.

---

## Implementation Subagents

| ID | Task | Dependencies |
|----|------|-------------|
| T8-A | DB migration — `restricted_areas.campaign_id`, `route_postcodes`, `demographic_feedback` tables | None — SQL for user to run |
| T8-B | Restricted areas modal fix — global (read-only) vs campaign-specific (editable) | T8-A |
| T8-C | Area resolver + disambiguation UI — postcodes.io `/places` + outcode → sectors | None |
| T8-D | Sector enrichment engine — postcodes.io sectors → OA21 codes → NOMIS tenure fetch | T8-C |
| T8-E | Exclusion filter + demographic filter + route chunker | T8-D |
| T8-F | Plan UI + route instantiation — table, toggles, bulk INSERT | T8-E |
| T8-G | Demographic feedback stub — record OA profile on enquiry instruction | T8-A, T8-F |

---

## API Rate Limit Strategy

- **postcodes.io:** 30 req/sec. For 20 sectors × 100 postcodes = 2000 unit postcodes max.
  Use bulk endpoint `/postcodes` (POST with array) — up to 100 per call → max 20 calls.
- **NOMIS:** No documented limit. Cache OA tenure data in `sessionStorage` — same OA may
  appear across multiple campaigns. Key: `nomis_oa_{oa21_code}`.

---

## ⚠️ KNOWN GAP — Critical Fix Required Before In-App Implementation

**Issue:** `route_postcodes` currently stores ONE row per Output Area (representative postcode only),
not one row per unit postcode. This means only ~16 postcodes are stored for Tingley (6 OAs × ~2-3
postcodes sampled) when the full route covers many more.

**Why this is critical:**
- **Enquiry auto-matching** — an enquiry from LS27 9DS won't match if LS27 9DS isn't in the table
- **Heatmap coverage** — only sampled postcodes will light up, not the full route area
- **Analytics** — sector-level join queries will miss real data

**Required fix for T8-F (in-app implementation):**
When instantiating routes, after grouping OAs, expand each OA to its FULL unit postcode list:

```javascript
// For each OA in a route:
const res = await fetch(`https://api.postcodes.io/postcodes?q=${sector}&limit=100`);
const unitPostcodes = res.result.filter(p => p.codes.oa21 === oa21_code);
// INSERT all of these into route_postcodes, not just one representative
```

For the LS27 9 / Tingley route this means iterating all unit postcodes returned for LS27 9*
and filtering to the 6 OAs in the route — giving ~16 rows not 6.

**Test run data:** Tingley route (36d762e1) currently has 6 rows (one per OA). These are the
confirmed unit postcodes that SHOULD be in the table:
- E00058082: LS27 9BJ, LS27 9DN, LS27 9DS, LS27 9DX
- E00058088: LS27 9BE, LS27 9EA
- E00058121: LS27 9AB, LS27 9AH
- E00058125: LS27 9DE, LS27 9DL, LS27 9DW
- E00058202: LS27 9AT, LS27 9AY, LS27 9AZ, LS27 9BB
- E00187102: LS27 9AE, LS27 9BF

**Action:** Fix in T8-F implementation. Also backfill the test campaign data in a new context window.

---

## Sources

- postcodes.io docs: https://postcodes.io/docs
- NOMIS API: https://www.nomisweb.co.uk/api/v01/
- NOMIS TS054 dataset: NM_2072_1
- ONS OA design spec: ~125 households per Output Area
- Turf.js: https://unpkg.com/turf@3.0.14/
