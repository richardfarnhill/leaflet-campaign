# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.
**Current focus:** Phase 6 T8 done. Phase 7 complete. Phase 8 next.

## Current Position

Phase: 8 of 9 (Auto-assignment & API)
Plan: 08-01 — Ready to start
Status: Phase 8 next — P7 fully closed (T1 route card details done)

Last activity: 2026-02-26 — Route card street names, map boundary polygon, P7 closed

Progress: [████████████████░░░░░] ~78% (7 of 9 phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 0 (work done manually outside GSD)
- Average duration: —
- Total execution time: —

## Accumulated Context

### Decisions

- [Phase 2]: No user roles — anyone can reserve, complete, or reassign any area
- [Phase 2]: Completed cards hidden from grid — only available/reserved shown
- [Phase 3]: Optional dual team member assignment — can assign 1 or 2 team members per area
- [Phase 3]: Cards display both team members (e.g. "John & Jane")
- [All]: Single-file app (index.html) — no build system, keep it that way for now
- [Phase 4]: "Areas" renamed to "Routes" in UI (DB table stays target_areas)
- [Phase 4]: Geocoding uses postcodes.io (free, no key) — planned from day 1 in STACK.md/PROJECT.md
- [Phase 4]: Map shows all routes as circle markers (grey=available, amber=reserved, green=completed)
- [Phase 5]: Team members are route-level, not campaign-level — assignment happens on individual route cards
- [Phase 5]: "All Campaigns" view exists via dropdown but campaign-level is the default; all stats/journal/map filter by currentCampaignId

### Pending Todos

- Phase 6: Enquiry recording and analytics (T1-T6)

### Blockers/Concerns

- **Cleanup needed (optional):** Drop unused `campaign_members` table:
  ```sql
  DROP TABLE IF EXISTS campaign_members CASCADE;
  ```
- **All Phase 5 migrations complete** - no blockers remaining

## Active Tasks

<!-- Multi-agent coordination — see .planning/COORDINATION.md for full protocol.
     REQUIRED: Claim here before making ANY code changes. Remove when done.
     Format: - [AGENT] [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC] -->

None.

## Session Continuity

Last session: 2026-02-26
Stopped at: T03 (RLS) in progress - needs Supabase RLS enablement
Resume file: None

## Phase 4 Task Checklist (04-01-PLAN.md)

| Task | Status | Agent |
|------|--------|-------|
| T1: Add Leaflet.heat | ✓ Done | OC |
| T2: View toggle + dashboard HTML | ✓ Done | Claude |
| T3: Map view + heatmap + enquiry markers | ✓ Done | OC |
| T4: Completion rate | ✓ Done | Claude |
| T5: Enquiry markers | ✓ Done (in T3) | OC |
| T6: Analytics charts (Chart.js) | ✓ Done | OC |
| T7: Add lat/lng + insert routes | ✓ Done (coords WRONG — T12 fixes) | Claude |
| T8: Remove legacy UI | ✓ Done | Claude |
| T9: Fix null reference (render()) | ✓ Done | OC |
| T10: Migrate delivery, rename to routes | ✓ Done | Claude |
| T11: App/DB sync review | ✓ Done | Claude |
| T12: Unique postcodes + geocode + legend | ✓ Done | Claude |
| T13: Map → route card navigation | ✓ Done | OC |
| T14: Format Delivery Journal as table | ✓ Done | OC |
| T15: Verify Phases 1-3 implementation | ✓ Done (code review) | OC |

## Phase 5 Task Checklist (05-01-PLAN.md)

| Task | Status | Agent |
|------|--------|-------|
| T1: All Campaigns option | ✓ Done | Claude |
| T2: Campaign config modal | ✓ Done | OC |
| T3: Config button | ✓ Done | OC |
| T4: DB-driven summary bar | ✓ Done | Claude |
| T5: Aggregated stats | ✓ Done | Claude |
| T6: Response rate config | ✓ Done | Claude |
| T7: New campaign UI | ✓ Done | Claude |
| T7a: Seed test campaign | ○ Partial (Richard) | - |
| T8: Remove hardcoded STAFF | ✓ Done | OC |
| T9: Restricted areas config + overlay | ✓ Done | OC |
| T10: Add missing DB columns | ✓ Done | - |
| T11: Team member management in config | ✓ Done (REMOVED - team members are route-level, not campaign-level) | OC |
| T12: Delivery journal edit | ✓ Done | OC |
| T13: Restricted areas config UI | ✓ Done | Claude |
| T14: Restricted areas as polygons | ✓ Done | Claude |

## Phase 6 Task Checklist (06-01-PLAN.md)

| Task | Status | Agent |
|------|--------|-------|
| T0.1: Per-postcode exclusion radius UI | ✓ Done | Claude |
| T1: DB migration (enquiries lat/lng cols) | ✓ Done | Claude |
| T1a: Route unknown default + target_area_id in modal | ✓ Done | Claude |
| T2: Enquiry recording modal | ✓ Done | OC |
| T3: Enquiry list view + edit/delete | ✓ Done | OC |
| T4: Enquiry map markers (fix lat/lng) | ✓ Done | Claude |
| T5: Finance projections from DB enquiries | ✓ Done | Claude |
| T5a: Remove finance_actuals table + dead code | ✓ Done | Claude |
| T6: Team progress view | ✓ Done | OC |
| T6b: Enquiry date not-null fix | ✓ Done | OC |
| T6c: Load team progress on page init | ✓ Done | OC |
| T6d: Campaign data isolation (Chinese wall) | ✓ Done | OC |
| T7: Leaderboards | ✓ Done (merged with T6) | OC |
| T8: Route creation UI + route_postcodes backfill | ✓ Done | Claude | route_postcodes backfilled (18 rows for Tingley); Add Route button + modal in index.html |
| T9: Route deletion UI | ✓ Done | OC | Delivered as Phase 7 T2 |
| T10: Phase review + gap identification | ✓ Done | OC | All flows verified: enquiry record→list→map→finance, campaign switch updates all views, data isolation working |

### T8 Handover Note (2026-02-26)

**Two jobs:**

**Job 1 — Backfill `route_postcodes` for "Testing Claude" campaign**
The table currently has 1 row per OA (representative postcode only). Each route needs full unit postcode expansion.
- Query DB: get all routes for "Testing Claude" campaign + their current `route_postcodes` rows (need `target_area_id`, `oa21_code`, representative postcode/sector)
- For each OA, query `https://api.postcodes.io/postcodes?q={sector}&limit=100`, filter results to that `oa21_code`, INSERT all matching unit postcodes into `route_postcodes`
- Tingley route confirmed OA→postcode mapping is in `.planning/ROUTE-PLANNING-ENGINE.md` — use as verification baseline (should end up with ~18 rows, not 6)
- Other 4 routes: derive sector from representative postcode already in DB, same expansion process

**Job 2 — Add "Add Route" button + modal to index.html (the actual T8 UI)**
See 06-01-PLAN.md Task 8 for full spec. Simple modal: Route Name, Postcode, House Count, Notes. On save: geocode via postcodes.io → POST to target_areas. Does NOT need to populate route_postcodes yet (that's T8-F, the full planning engine).

**Supabase MCP:** Tools are `mcp__claude_ai_Supabase__execute_sql` / `mcp__claude_ai_Supabase__apply_migration`. Restart Claude Code first. Full setup in MEMORY.md.

## Phase 7 Task Checklist

| Task | Status | Agent |
|------|--------|-------|
| T1: Route card details - street names, map boundary | ✓ Done | Claude | streets shown on card click (▼ toggle); "Map" button highlights route postcodes on map view |
| T2: Route deletion UI | ✓ Done | OC | Delete button on route cards, confirmation modal, cascades to deliveries/reservations |
| T3: RLS policies verification | ✓ Done | OC | RLS enabled on all tables, public read policies (2026-02-26) |
| T4: Route completion - explicit leaflet count + rolling adjustment | ✓ Done | OC | Already implemented: modal requires count, saves to DB, displays remaining |
| T5: Security - move credentials to config.js | ✓ Done | OC |
| T6: DB-driven Summary Bar fix (CFG-03) | ✓ Done | OC |
| T7: Phase review | ✓ Done | Claude | T1 complete — all P7 tasks done. P7 fully closed. |

## Phase 8 Task Checklist

| Task | Status | Notes |
|------|--------|-------|
| T1: Create campaign - enhance with route creation questions | ○ Pending | Review after P7 |
| T2: Global exclusion areas review | ○ Pending | Clarify DB state |
| T3: Prompt new route when 500 houses short | ○ Pending | |
| T4: Auto-assign enquiries to routes | ○ Pending | Critical for leaderboard accuracy |
| T5: API endpoints (Supabase) | ○ Pending | |
| T6: Demographic feedback table from enquiries | ○ Pending | |
| T7: Migrate real campaigns into new data model | ○ Pending | Richard's existing real campaign data (routes, deliveries, enquiries) needs refactoring into campaigns/target_areas/route_postcodes/enquiries schema. Probably done interactively with Richard. |

## Phase 9 Task Checklist (Backlog)

| Task | Status | Notes |
|------|--------|-------|
| T1: Dark mode toggle (system default) | ○ Pending | |
| T2: CSV/Sheets export | ○ Pending | |
| T3: Gmail notifications | ○ Pending | |
| T4: Full ClickUp integration | ○ Pending | |
| T5: Planning screen v2 | ○ Pending | |

## Backlog (Consider Later)

- ClickUp webhook DB table + API stub
- CSV/Sheets export
- Gmail notifications  
- Full ClickUp integration
- Planning screen v2
