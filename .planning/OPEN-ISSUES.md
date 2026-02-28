# Open Issues

**Project:** Leaflet Campaign Tracker
**Last updated:** 2026-02-27
**Purpose:** Canonical register of unresolved concerns, contradictions, and open questions. Update this file when issues are discovered or resolved.

---

## OI-01 — Street Name Source (RESOLVED ✅ 2026-02-28)

**Status:** RESOLVED — Nominatim reverse geocoding is the solution
**Resolved by:** Claude via research + implementation
**Affects:** `target_areas.streets` enrichment (Mode B), [ROUTE-FLAGGING.md](./ROUTE-FLAGGING.md), [ROUTE-PLANNING-ENGINE.md](./ROUTE-PLANNING-ENGINE.md), `~/.claude/commands/leaflet-plan-routes.md`

### The Issue (Now Resolved)

Multiple documents incorrectly claimed `target_areas.streets` was populated from postcodes.io `thoroughfare` field, which **does not exist** in the API response.

### The Solution

**Use Nominatim reverse geocoding** (OpenStreetMap):
- Free, CORS-safe, no API key required
- `GET https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json`
- Returns `address.road` — the street name
- Rate limit: 1 req/sec (manageable for ~534 postcodes = ~9 min)

### Implementation

1. **Python enrichment script:** `scripts/enrich_streets_os_names.py` (created 2026-02-28)
   - Fetches postcodes for a route via Supabase
   - Calls Nominatim for each postcode (respecting 1 req/sec rate limit)
   - Deduplicates and sorts street names
   - Updates `target_areas.streets` in DB
   - Tested successfully on E2E Test Route: `["Dewsbury Road"]`

2. **New Claude skill:** `/leaflet-enrich-streets` (created 2026-02-28)
   - High-level orchestration for street enrichment
   - Handles multi-route batches
   - Integrates with leaflet-plan-routes skill

3. **Updated docs:**
   - leaflet-plan-routes.md: Now points to Nominatim method, `/leaflet-enrich-streets` skill
   - ROUTE-FLAGGING.md: Updated table + street extraction section
   - This file: OI-01 marked as resolved

### Verification

✅ E2E test successful:
- Route: "E2E Test Route" (WF3 1AA)
- Before: `streets: []`
- After: `streets: ["Dewsbury Road"]`
- Status: Updated in DB (confirmed via SQL query)

### Known Limitations

- Rate-limited to 1 req/sec (Nominatim policy)
- Some postcodes (PO boxes, rural) may not return a street
- Data reflects OpenStreetMap accuracy (may lag new developments)

---

## OI-02 — Password Bypass in Production Code ⚠️

**Status:** Known, intentional (testing) — must fix before go-live
**Affects:** `index.html` line ~24 (IIFE)

The password check is bypassed with `if(false && !getCookie(COOKIE)){`. Remove `false &&` before going live.

---

## OI-03 — route_postcodes Sector Overlap

**Status:** Known limitation, deferred to Planning Screen v2
**Affects:** `14k_Feb_2026` campaign, all routes sharing a sector

Routes that share a postcode sector (e.g. two routes both in SK9 3) received identical postcode sets during the ONSPD backfill. Proper per-route geographic boundary definition is deferred to Planning Screen v2 (Phase 10 T5).

---

## Resolved Issues (archive)

| ID | Issue | Resolution | Date |
|----|-------|------------|------|
| — | Phase 9 T2b trigger not implemented | Deployed and tested — `trg_enrich_demographic_feedback` confirmed working | 2026-02-26 |
| — | NOMIS enrichment silent failure (`created_at` vs `recorded_at`) | Fixed column name in ORDER BY | 2026-02-26 |
| — | RLS UPDATE policy missing on demographic_feedback | Policy added | 2026-02-26 |
