# Routes — Authoritative Reference

**Project:** Leaflet Campaign Tracker
**Covers:** Route flagging, planning (Mode A), enrichment (Mode B), street names, data sources, scripts
**Last updated:** 2026-03-04
**Status:** Authoritative — update this file when any route rule, data source, or script changes

> This file replaces `ROUTE-FLAGGING.md` and `ROUTE-PLANNING-ENGINE.md` (both archived).

---

## Quick Index

| I want to... | Go to |
|---|---|
| Understand when a campaign/route is flagged | [Flagging Rules](#flagging-rules) |
| Create new routes from scratch | [Mode A — Create Routes](#mode-a--create-routes) |
| Enrich existing routes with real data | [Mode B — Enrich Existing Routes](#mode-b--enrich-existing-routes) |
| Add street names to routes | [Street Name Enrichment](#street-name-enrichment-oi-01-resolved) |
| Understand NOMIS data sources | [Data Sources](#data-sources) |
| Find the right script | [Scripts Reference](#scripts-reference) |
| Re-plan the 14k Feb 2026 campaign | `.planning/campaigns/14k_Feb_2026/REPLAN-14K-PROMPT-CORRECTED.md` |
| Re-plan the LS27 areas campaign | `.planning/campaigns/LS27/` |
| Check postcode OA loading progress | `.planning/POSTCODE_LOAD_STATUS.md` |

---

## Flagging Rules

### Campaign-Level: `needs_routing`

**What it means:** Campaign does not have enough routes to cover its leaflet target.

**DB column:** `campaigns.needs_routing` (boolean, default `false`)

**Set `true`:** On campaign creation (always — zero routes at start).

**Auto-cleared when:** `(sum of route house_counts) + (sum of leaflets_delivered)` comes within 500 of `campaign.target_leaflets`.

**Checked by:** `checkAndPromptRouting()` in `index.html` — runs on page load, after route add, after route delete.

**Action:** Run `/leaflet-plan-routes` in **Mode A**.

---

### Route-Level: Implicit Enrichment Detection

**What it means:** Route exists in DB but lacks real Census household counts, postcode coverage, or street names.

**No DB flag column** — detected at query time:

```sql
SELECT ta.area_name, ta.postcode, ta.house_count,
  COUNT(rp.id) as postcode_count,
  SUM(CASE WHEN rp.household_count IS NULL THEN 1 ELSE 0 END) as missing_hh_count
FROM target_areas ta
LEFT JOIN route_postcodes rp ON rp.target_area_id = ta.id
WHERE ta.campaign_id = '{campaign_id}'
GROUP BY ta.id
HAVING COUNT(rp.id) = 0
    OR SUM(CASE WHEN rp.household_count IS NULL THEN 1 ELSE 0 END) > 0
ORDER BY ta.area_name;
```

**A route needs enrichment if:**
- Zero rows in `route_postcodes`, OR
- Rows present but `household_count IS NULL`, OR
- `target_areas.streets = '{}'` (empty array)

**Action:** Run `/leaflet-plan-routes` in **Mode B** — or `/leaflet-enrich-streets` for streets only.

---

## Route Size Rules

| Rule | Value |
|------|-------|
| Minimum doors | 500 |
| Maximum doors | 1,000 |
| Target midpoint | 750 |
| Rounding | Nearest 50 (Census figures look arbitrary; round before storing) |
| Split threshold | If enrichment reveals > 1,000 doors: split into A and B |
| Split naming | `[Route Name] A` / `[Route Name] B` — never North/South/East/West |

**True house_count per route:** Use `SUM(DISTINCT oa household_count)` — NOT `SUM(household_count)` across all postcode rows (overcounts because OA value is repeated per postcode).

**Re-plan vs enrich:** A route with 20+ unique OAs for a supposed 1,000-door route was backfilled sector-wide (ONSPD problem). It needs **Mode A re-planning**, not Mode B enrichment. Expected OAs per 1,000-door route: 7–10 (avg ~125 hh/OA).

---

## Data Sources

All sources are free, no API key required, CORS-enabled.

### postcodes.io

**Base URL:** `https://api.postcodes.io`
**Rate limit:** 30 req/sec

| Endpoint | Use |
|----------|-----|
| `GET /places?q={name}&limit=20` | Resolve place name → outcode |
| `GET /postcodes?q={sector}&limit=100` | All unit postcodes in a sector |
| `GET /postcodes/{postcode}` | Single postcode → lat/lng, OA21 code |

**Key fields:** `latitude`, `longitude`, `oa21`, `outcode`, `admin_district`

---

### NOMIS — Census 2021 Tenure

**Base URL:** `https://www.nomisweb.co.uk/api/v01`
**Dataset:** `NM_2072_1` — Census 2021 Table TS054: Tenure
**CORS:** Confirmed browser-callable (`Access-Control-Allow-Origin: *`)

**⚠️ VERIFIED PATTERNS (2026-02-27 — previous docs were wrong):**

- `NM_2001_1` and `NM_2059_1` return NO data at OA level — do not use them
- `NM_2072_1` is the only working dataset for both household counts AND owner-occupied %
- Alpha OA21 codes (e.g. `E00025680`) work directly — NO `def.sdmx.json` NomisKey lookup needed

```
# Household count (total per OA):
GET /dataset/NM_2072_1.data.json?geography=E00025680,E00025691,...&c2021_tenure_9=0&measures=20100

# Owner-occupied % (owned outright + mortgage):
GET /dataset/NM_2072_1.data.json?geography=E00025680,...&c2021_tenure_9=1001&measures=20301

Response: obs[].geography.geogcode → OA alpha code, obs[].obs_value.value → count/percent
Batch: up to 100 alpha codes per request.
```

**Demographic filter:** Owner-occupied ≥ 60% (target: 60–80%; above 80% is fine to include).

---

### Nominatim — Street Names

**Base URL:** `https://nominatim.openstreetmap.org`
**Rate limit:** 1 req/sec per IP — strictly enforced
**Key required:** No

```
GET /reverse?lat={lat}&lon={lng}&format=json
Extract: address.road (fallback: address.residential)
```

**⚠️ Do NOT parallelise routes** — 429s from Nominatim persist for several minutes. Run routes sequentially.

Use `scripts/enrich_sequential.py` — it handles rate limiting (1.5s delay, 15s back-off on 429) and targets only zero-street routes automatically.

---

### Turf.js — Geospatial

Already on stack (CDN: `https://unpkg.com/turf@3.0.14/turf.min.js`)

Used for exclusion radius checks:
```js
turf.distance(point, restrictedCentre, {units: 'miles'}) < radius
```

---

## Restricted Areas (Global Exclusions)

Hardcoded in DB with `campaign_id = NULL` (global). These never change.

| Postcode | Location | Radius |
|----------|----------|--------|
| WA14 1QP | Altrincham (own office) | 2 miles |
| SK4 4QG | Stockport area | 2 miles |
| SK4 4DT | Stockport area | 2 miles |
| OL10 4NN | Heywood | 2 miles |

Campaign-specific exclusions: `campaign_id` set, managed via config modal.

DB query (includes both global and campaign-specific):
```
/rest/v1/restricted_areas?or=(campaign_id.is.null,campaign_id.eq.{currentCampaignId})
```

---

## Mode A — Create Routes

**Trigger:** Campaign flagged `needs_routing = true`.
**Skill:** `/leaflet-plan-routes`

**Process:**
1. Resolve area description → outcode(s) via postcodes.io `/places`
2. Expand outcodes → sectors → unit postcodes via `/postcodes?q={sector}`
3. Group postcodes by OA21 code
4. Fetch NOMIS NM_2072_1: household counts + owner-occupied % (batched, up to 100 OA codes/request)
5. Apply demographic filter (≥60% owner-occupied)
6. Apply exclusion radius checks (Turf.js)
7. Cluster remaining OAs into routes of 500–1,000 doors (target: 750), geographically contiguous
8. Name routes: `{admin_district} {N}` (e.g. "Didsbury 1", "Didsbury 2")
9. Present plan table for user approval
10. On approval: `POST /rest/v1/target_areas` + bulk `POST /rest/v1/route_postcodes`

**Rate limiting:** postcodes.io 30 req/sec — use bulk POST `/postcodes` (up to 100/call). Cache NOMIS OA data in `sessionStorage` keyed `nomis_oa_{oa21_code}`.

---

## Mode B — Enrich Existing Routes

**Trigger:** Route has zero postcodes, NULL household counts, or empty `streets[]`.
**Skill:** `/leaflet-plan-routes` (Mode B) or `/leaflet-enrich-streets` (streets only)

**Full enrichment output (all three required):**

| Field | Source |
|-------|--------|
| `target_areas.house_count` | NOMIS NM_2072_1, rounded to nearest 50 |
| `route_postcodes.household_count` | NOMIS NM_2072_1 per OA, rounded to nearest 50, repeated per postcode in that OA |
| `target_areas.streets` | Nominatim reverse geocode → `address.road`, deduplicated, sorted |

---

## Street Name Enrichment (OI-01 RESOLVED)

**Solution:** Nominatim reverse geocoding. Resolved 2026-02-28.

**Why not postcodes.io?** The `thoroughfare` field does not exist in postcodes.io responses. Nominatim is the correct free alternative.

**Process:**
```python
for pc in postcodes:
    response = requests.get(f'https://nominatim.openstreetmap.org/reverse?lat={pc.lat}&lon={pc.lng}&format=json',
                            headers={'User-Agent': 'leaflet-campaign/1.0'})
    if 'road' in response['address']:
        streets.append(response['address']['road'])

streets = sorted(set(streets))
# UPDATE target_areas SET streets = streets WHERE id = route_id
```

**Script:** `scripts/enrich_sequential.py` — targets zero-street routes only, safe to re-run.

```bash
cd "c:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign"
python scripts/enrich_sequential.py
```

Do not interrupt mid-route — partial results require manual cleanup. ~25–50 postcodes/route = ~1–2 min/route.

---

## Scripts Reference

| Script | What it does | When to use |
|--------|-------------|-------------|
| `scripts/enrich_sequential.py` | Nominatim street enrichment, sequential, rate-limited | Enrich `streets[]` for zero-street routes |
| `scripts/load_postcode_area.py` | Load ONSPD postcode-OA mapping by outcode | Adding new postcode areas to `postcode_oa_lookup` |
| `scripts/fetch_nomis_households.py` | NOMIS household count queries | Manual household count checks |
| `scripts/backfill_demographics.js` | Bulk demographic enrichment from NOMIS | Backfill historic `demographic_feedback` |
| `scripts/nomis_backfill.py` | Legacy NOMIS backfill | Replaced by `backfill_demographics.js` — use sparingly |
| `.planning/postcode-data/fetch.py` | ONSPD sector filtering | Pre-filtering ONSPD CSV before bulk load |
| `scripts/load_priority_postcodes.sql` | SQL for priority postcode loading | Run in Supabase SQL editor |
| `scripts/update_owner_pct.sql` | Owner-occupied % update | Run in Supabase SQL editor |

**Running Python scripts:**
```bash
python "c:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/scripts/{script}.py"
```

**SSL errors on NOMIS:** Add `ssl._create_default_https_context = ssl._create_unverified_context` at top of script.

---

## Enquiry Auto-Matching (downstream)

When enquiry postcode is recorded:
1. Normalise (strip spaces, uppercase)
2. Look up `route_postcodes WHERE postcode = {enquiry_postcode} AND target_area_id IN (routes for campaign)`
3. Match found → auto-populate `enquiries.target_area_id`
4. No match → check sector (first 5 chars) in `route_postcodes.postcode_sector`
5. Still no match → leave as "Route unknown"

This is why storing full unit postcodes in `route_postcodes` is critical.

---

## ONSPD Backfill Notes

The original approach of using postcodes.io API to expand sectors was blocked by WSL networking. The working solution:

1. Download ONSPD (ONS Postcode Directory, Nov 2025) — 1.4GB CSV
2. Filter to relevant sectors using `.planning/postcode-data/fetch.py`
3. Load into Supabase `postcode_oa_lookup` via `scripts/load_postcode_area.py`
4. SQL JOIN inserts matching postcodes into `route_postcodes`

**Known limitation (OI-03):** Routes sharing a sector receive identical postcode sets. Per-route geographic boundary definition is deferred to Planning Screen v2.

---

*Update this file when any route rule, data source, NOMIS pattern, or script changes.*
