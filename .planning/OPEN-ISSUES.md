# Open Issues

**Project:** Leaflet Campaign Tracker
**Last updated:** 2026-02-27
**Purpose:** Canonical register of unresolved concerns, contradictions, and open questions. Update this file when issues are discovered or resolved.

---

## OI-01 — Street Name Source Unknown ⚠️

**Status:** Unresolved
**Affects:** `target_areas.streets` enrichment (Mode B), [ROUTE-FLAGGING.md](./ROUTE-FLAGGING.md), [ROUTE-PLANNING-ENGINE.md](./ROUTE-PLANNING-ENGINE.md), `~/.claude/commands/leaflet-plan-routes.md`

### The contradiction

Multiple documents state that `target_areas.streets` is populated from the postcodes.io `thoroughfare` field:

- **ROUTE-FLAGGING.md** (line 76): *"`target_areas.streets` | postcodes.io `thoroughfare` field per unit postcode"*
- **leaflet-plan-routes.md** (line 45): *"Each postcode result includes a `thoroughfare` field — this is the street name."*

However:
- The postcodes.io API (both `GET /postcodes/{postcode}` and `GET /postcodes?q={sector}` and bulk `POST /postcodes`) does **not** return a `thoroughfare` field in any response.
- **ROUTE-PLANNING-ENGINE.md** (line 377) itself notes: *"admin_ward is the best proxy for street-level geographic context (no street names in postcodes.io)"* — directly contradicting the above.

### What we know

- Routes Tingley and Churwell do have `streets` populated correctly in the DB (verified 2026-02-27).
- Those streets appear accurate (e.g. Tingley: Airedale Avenue, Asquith Avenue, Back Lane, ...).
- The source of those street names is **currently unknown** — they were not traced to a specific API call or script.

### What needs investigating

1. Check git log for the commit that first populated `streets` for Tingley/Churwell — trace the actual code/query used.
2. Determine if postcodes.io has a different endpoint that returns street names (e.g. via a `places` endpoint or a premium tier).
3. Consider alternatives: OS Names API (requires key), Nominatim/OpenStreetMap (free, no key, CORS-ok), or manual curation.
4. Once source confirmed, update ROUTE-FLAGGING.md and leaflet-plan-routes.md skill with correct method.

### Impact

Mode B enrichment currently cannot reliably populate `target_areas.streets` via any documented method. Existing populated routes are correct but their provenance is unclear. New enrichment runs will leave `streets = []`.

### Todos

- [ ] Trace git history of first streets population (Tingley/Churwell)
- [ ] Test Nominatim reverse-geocode as candidate replacement
- [ ] Update all three affected docs once source confirmed

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
