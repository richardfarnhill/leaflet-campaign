# Route Flagging & Enrichment Rules

**Project:** Leaflet Campaign Tracker
**Last updated:** 2026-02-27
**Status:** Authoritative reference — update this file when rules change

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
- It has rows but `household_count IS NULL` on any of them

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
| Unit postcodes + OA21 codes | postcodes.io | `GET /postcodes?q={sector}&limit=100` |
| Household counts per OA | NOMIS NM_2059_1 (TS041) | Bulk NomisKey lookup then data query |
| Owner-occupied % per OA | NOMIS NM_2072_1 (TS054) | Same NomisKey pattern |

**NOMIS household count pattern (NM_2059_1 — NOT NM_2001_1 which returns nothing at OA level):**
```
Step 1: GET /dataset/NM_2059_1/geography/{oa1},{oa2},...def.sdmx.json  → NomisKeys
Step 2: GET /dataset/NM_2059_1.data.json?geography={key1},{key2},...&measures=20100 → counts
```

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
| `~/.claude/commands/leaflet-plan-routes.md` | Skill: Mode A (create) + Mode B (enrich) |
| This file | Authoritative rules reference |
