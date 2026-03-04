# Route Flagging & Enrichment Rules

**Project:** Leaflet Campaign Tracker
**Last updated:** 2026-02-27
**Status:** Authoritative reference — update this file when rules change

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [STATE.md](./STATE.md) | Current project position & outstanding items |
| [ROUTE-PLANNING-ENGINE.md](./ROUTE-PLANNING-ENGINE.md) | Technical spec for route creation (Mode A) and data sources |
| [OPEN-ISSUES.md](./OPEN-ISSUES.md) | Unresolved concerns — including OI-01 (street name source) |
| `~/.claude/commands/leaflet-plan-routes.md` | Skill: executes Mode A (create) and Mode B (enrich) |

---

## Overview

There are two distinct situations that flag a campaign or route as needing attention:

1. **Campaign needs more routes** — not enough doors to deliver to
2. **Route needs enrichment** — exists in DB but lacks real postcode/household data

Both are detectable from the DB. Neither requires a UI-visible "flag" beyond what already exists.

---

## 1. Campaign-Level Flag: `needs_routing`

### What it means
A campaign does not have enough routes to cover its leaflet target.

### DB column
`campaigns.needs_routing` — boolean, default `false`

### When it is set to `true`
- On campaign creation (always — a new campaign has zero routes)

### When it is auto-cleared
- When `(sum of route house_counts) + (sum of leaflets_delivered)` comes within 500 of `campaign.target_leaflets`
- Checked on: page load, after any route is added, after any route is deleted

### The 500-leaflet rule
If `target_leaflets - (total_house_count + total_delivered) > 500`, the campaign is considered short and the user is prompted to add more routes via `checkAndPromptRouting()` in `index.html`.

### What to do
Run `/leaflet-plan-routes` in **Mode A** (create new routes) for that campaign.

---

## 2. Route-Level Enrichment: Implicit Detection

### What it means
A route was manually created with an arbitrary name and house_count. It lacks real Census household counts and full postcode coverage.

### There is no DB flag column for this.
Enrichment need is detected at query time:

```sql
-- Routes needing enrichment in a campaign:
SELECT ta.area_name, ta.postcode, ta.house_count,
  COUNT(rp.id) as postcode_count,
  SUM(CASE WHEN rp.household_count IS NULL THEN 1 ELSE 0 END) as missing_hh_count
FROM target_areas ta
LEFT JOIN route_postcodes rp ON rp.target_area_id = ta.id
WHERE ta.campaign_id = '{campaign_id}'
GROUP BY ta.id
HAVING COUNT(rp.id) = 0                          -- no postcodes at all
    OR SUM(CASE WHEN rp.household_count IS NULL THEN 1 ELSE 0 END) > 0  -- postcodes but no counts
ORDER BY ta.area_name;
```

A route needs enrichment if:
- It has **zero rows** in `route_postcodes`, OR
- It has rows but `household_count IS NULL` on any of them, OR
- `target_areas.streets` is an empty array `{}`

### Full enrichment output (all three must be populated)

| Field | Source | Notes |
|-------|--------|-------|
| `target_areas.house_count` | NOMIS NM_2059_1, rounded to nearest 50 | Replaces arbitrary manual value |
| `route_postcodes.household_count` | NOMIS NM_2059_1 per OA, rounded to nearest 50 | One value per OA, repeated across all postcodes in that OA |
| `target_areas.streets` | Nominatim reverse geocode `address.road` per postcode (OI-01 RESOLVED) | Deduplicated, sorted, nulls removed. This is what the team sees on the card (click-to-expand ▼). Use `/leaflet-enrich-streets` skill. |

### Street name extraction (OI-01 RESOLVED)

Use **Nominatim reverse geocoding** to fetch street names:

For each unit postcode in the route:
1. Call: `GET https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json`
2. Extract: `address.road` field (the street name)
3. Collect all non-null values, deduplicate, sort alphabetically
4. Write as `TEXT[]` to `target_areas.streets`

**Use the `/leaflet-enrich-streets` skill for this task** — it handles the API calls, rate limiting, and DB updates automatically.

```python
# High-level pseudocode:
streets = []
for pc in postcodes:
    response = requests.get(f'https://nominatim.openstreetmap.org/reverse?lat={pc.lat}&lon={pc.lng}&format=json')
    if 'road' in response['address']:
        streets.append(response['address']['road'])

streets = sorted(set(streets))  # Deduplicate and sort
# UPDATE target_areas SET streets = streets WHERE id = route_id
```

⚠️ **Why not postcodes.io?** The `thoroughfare` field does not exist in postcodes.io responses. Nominatim is the practical free alternative. See [OPEN-ISSUES.md OI-01](./OPEN-ISSUES.md).

### What to do
Run `/leaflet-plan-routes` in **Mode B** (enrich existing route) for each flagged route.

---

## Route Size Rules

Every route must have between **500 and 1000 doors** (Census households, rounded to nearest 50).

- Target midpoint: **750**
- If enrichment reveals a route exceeds 1000: split into A and B before writing to DB
- Naming on split: `[Route Name] A` / `[Route Name] B` — never North/South/East/West

### Household count rounding
Always round Census OA household counts to the nearest 50 for `house_count` on the route card and `household_count` in `route_postcodes`. Exact Census figures look arbitrary to team members.

---

## Data Sources

| Data | Source | API / Dataset |
|------|--------|--------------|
| Unit postcodes + OA21 codes + street names | postcodes.io | `GET /postcodes?q={sector}&limit=100` |
| Household counts per OA | NOMIS NM_2072_1 (TS054) | Direct alpha code query — see below |
| Owner-occupied % per OA | NOMIS NM_2072_1 (TS054) | Same dataset, different measure |

**⚠️ VERIFIED NOMIS patterns (updated 2026-02-27 — previous docs were wrong):**

NM_2001_1 and NM_2059_1 return no data at OA level. Use NM_2072_1 for everything.
Alpha OA21 codes work directly — NO def.sdmx.json NomisKey lookup needed.

```
# Household count (total per OA):
GET /dataset/NM_2072_1.data.json?geography=E00025680,E00025691,...&c2021_tenure_9=0&measures=20100

# Owner-occupied % (owned outright + mortgage):
GET /dataset/NM_2072_1.data.json?geography=E00025680,...&c2021_tenure_9=1001&measures=20301

Response: obs[].geography.geogcode → OA alpha code, obs[].obs_value.value → count/percent
Batch: up to 100 alpha codes per request.
```

Also: the `route_postcodes` table's `household_count` field should store the rounded OA count on every row with that `oa21_code` (same value repeated per postcode). To get the true house_count per route, use `SUM(DISTINCT oa household_count)` — not `SUM(household_count)` across all postcode rows (which overcounts).

**Re-planning vs enrichment:**
A route with 20+ unique OAs for a supposed 1,000-door route was loaded sector-wide (ONSPD backfill problem). It needs **re-planning** (Mode A), not enrichment (Mode B). Expected OAs per 1,000-door route: 7–10 (avg ~125 hh/OA).

---

## Environment Notes

- **Shell:** Git Bash on Windows — `/tmp` does not work. Use full Windows paths e.g. `c:/Users/richa/...`
- **Python:** `python "c:/path/to/script.py"` for API calls. Use `urllib` or `requests` with `verify=False` if NOMIS SSL errors occur.

---

## Where This Is Implemented

| Location | What it covers |
|----------|---------------|
| `index.html` — `checkAndPromptRouting()` | Campaign `needs_routing` flag — checks on load/add/delete |
| `index.html` — `checkAndPromptRouting()` | Auto-clears flag when shortfall ≤ 500 |
| `supabase_schema.sql` | `campaigns.needs_routing` column definition |
| `.planning/ROUTE-PLANNING-ENGINE.md` | Full technical spec for route creation (Mode A) |
| `.planning/REPLAN-14K-FEB-2026.md` | Prompt + instructions to re-plan 14k campaign routes |
| `~/.claude/commands/leaflet-plan-routes.md` | Skill: Mode A (create) + Mode B (enrich), updated NOMIS patterns |
| This file | Authoritative rules reference |
