# Route Planning Engine — Technical Design

**Project:** Leaflet Campaign Tracker
**Version:** 1.0
**Last updated:** 2026-02-27
**Status:** Partially implemented — Mode B (enrich) in use; Mode A (create) available via skill

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [STATE.md](./STATE.md) | Current project position |
| [ROUTE-FLAGGING.md](./ROUTE-FLAGGING.md) | Authoritative rules: when to flag, enrich, size constraints |
| [OPEN-ISSUES.md](./OPEN-ISSUES.md) | Unresolved concerns — including OI-01 (street name source) |
| `~/.claude/commands/leaflet-plan-routes.md` | Skill: Mode A (create routes) and Mode B (enrich existing routes) |

---

## Overview

The Route Planning Engine generates a campaign's delivery routes from a natural-language area
description. It resolves the area to constituent postcode sectors, filters by demographic
criteria (owner-occupied tenure), excludes restricted areas by radius, chunks the remaining
sectors into 500-1000 door delivery routes, and presents a plan for the user to approve and
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

For precise counts, use NOMIS `NM_2059_1` (TS041 — Number of Households):
```
Step 1: GET /dataset/NM_2059_1/geography/{oa1},{oa2},...def.sdmx.json  → NomisKeys per OA
Step 2: GET /dataset/NM_2059_1.data.json?geography={key1},{key2},...&measures=20100 → household counts
```
⚠️ Do NOT use NM_2001_1 — it returns no data at OA21 level.
Round all counts to nearest 50 before storing — exact Census figures look arbitrary to team members.

**House count per route = sum of household counts across all OAs in that route.**
This is what populates `target_areas.house_count` — the number the user sees on the card.

---

### 4. Turf.js — Geospatial Operations

Already on stack (CDN: `https://unpkg.com/turf@3.0.14/turf.min.js`)

Used for:
- **Exclusion radius check:** `turf.distance(point, restrictedCentre, {units:'miles'}) < radius`
- **Route chunking:** Cluster OA centroids into groups of 500-1000 doors using proximity
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

**Auto-enrichment (Phase 9 — DEM-02/DEM-03 — COMPLETE):**
`owner_occupied_pct` is populated automatically via on-demand NOMIS call — no pre-loading required:

1. **Browser JS (Phase 9):** After an instructed enquiry is saved, `enrichDemographicFeedback()` 
   calls NOMIS NM_2072_1 (TS054 Tenure) API directly from the browser to get owner_occupied_pct.
   Works for ANY postcode, not just those in route_postcodes.

2. **Backfill script:** `scripts/backfill_demographics.js` can be run to enrich historic data.

**Result:** Every instructed enquiry row automatically carries its OA's tenure % for analytics.

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
- **Route size:** [500] – [1000] doors
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
6. Clusters remaining OAs into routes of 500-1000 doors (proximity grouping)
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

## ✅ Backfill Approach — ONSPD (Resolved 2026-02-26)

The original approach of using postcodes.io API to expand sectors was blocked by WSL networking
issues. The solution used was:

1. Download ONSPD (ONS Postcode Directory, Nov 2025) — 1.4GB CSV, ~2.5M postcodes
2. Filter to relevant sectors only using a Python script → ~3,146 rows
3. Load filtered CSV into a temporary `onspd` Supabase staging table
4. Run a SQL JOIN to insert all matching postcodes into `route_postcodes` for all 15 routes
5. Drop the staging table

**Result:** All 15 routes in `14k_Feb_2026` campaign now have full unit postcode coverage
(4,596 rows total, 234–399 postcodes per route).

**Known limitation:** Routes sharing a sector (e.g. two routes both in SK9 3) receive identical
postcode sets. Proper per-route geographic boundary definition is deferred to Planning Screen v2.

**For future route instantiation (T8-F):** The same ONSPD approach is recommended over
postcodes.io API calls — more reliable, no rate limits, no WSL networking issues. Keep the
ONSPD filtered.csv or the filter script at `.planning/postcode-data/fetch.py` for reuse.

**Data source note:** ONSPD does NOT contain street names. Street names on route cards were intended to use postcodes.io `thoroughfare` field, but this field has **not been confirmed** to exist in any postcodes.io API response. See [OPEN-ISSUES.md OI-01](./OPEN-ISSUES.md) — street name source is currently unresolved.

---

## Environment Notes

- **Shell:** Git Bash on Windows — `/tmp` does not work. Use full Windows paths: `c:/Users/richa/...`
- **Python scripts:** `python "c:/path/to/script.py"` — works fine for API calls with `requests` or `urllib`
- **SSL:** Use `ssl.create_default_context(); ctx.verify_mode = ssl.CERT_NONE` for NOMIS if SSL errors occur

---

## Related Documents

- **ROUTE-FLAGGING.md** — authoritative rules: when routes/campaigns are flagged, size rules, enrichment detection
- **`~/.claude/commands/leaflet-plan-routes.md`** — the skill that executes both Mode A (create) and Mode B (enrich)

---

## Sources

- postcodes.io docs: https://postcodes.io/docs
- NOMIS API: https://www.nomisweb.co.uk/api/v01/
- NOMIS TS054 dataset: NM_2072_1 (tenure/owner-occupied)
- NOMIS TS041 dataset: NM_2059_1 (household counts — use this, not NM_2001_1)
- ONS OA design spec: ~125 households per Output Area
- Turf.js: https://unpkg.com/turf@3.0.14/
