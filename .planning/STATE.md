# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.
**Current focus:** Phase 5 complete - ready for Phase 6

## Current Position

Phase: 5 of 7 (Campaign Management)
Plan: 05-01 — All tasks done. Phase 5 complete.
Status: Complete — ready for Phase 6
Last activity: 2026-02-25 — Removed campaign_members code (team members are route-level)

Progress: [████████████████████] 100%

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

- Claude [06-T0.1] — Per-postcode exclusion radius UI — claimed 2026-02-25 22:00 UTC

## Session Continuity

Last session: 2026-02-25
Stopped at: T13 done. T14 (map polygons) is next — start new chat.
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
| T0.1: Per-postcode exclusion radius UI | ○ Pending | - |
| T1: DB migration (enquiries lat/lng cols) | ○ Pending | - |
| T2: Enquiry recording modal | ✓ Done | OC |
| T3: Enquiry list view + edit/delete | ✓ Done | OC |
| T4: Enquiry map markers (fix lat/lng) | ○ Pending | - |
| T5: Finance projections from DB enquiries | ○ Pending | - |
| T6: Team progress view | ○ Pending | - |
| T7: Leaderboards | ○ Pending | - |
| T8: Route creation UI | ○ Pending | - |
| T9: Route deletion UI | ○ Pending | - |
| T10: Phase review + gap identification | ○ Pending | - |
