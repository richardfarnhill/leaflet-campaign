# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.
**Current focus:** Phase 5 - Campaign Management (in progress)

## Current Position

Phase: 4 of 7 (Analytics & Heatmaps)
Plan: 04-01 — T1-T14 complete. T15 (phase verification) is the only remaining task.
Status: Near complete
Last activity: 2026-02-25 — T11 done: removed dead legacy queries, linked delivery to campaign, added CFG-03 to Phase 5.

Progress: [████████░░░░░░░░░░░░] ~40%

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

### Pending Todos

- T15: Verify Phases 1-3 E2E flows before Phase 5 starts

### Blockers/Concerns

- **T7 error (Claude):** ~~lat/lng inserted as hardcoded approximations~~ — FIXED by T12. All 15 routes now have unique street postcodes geocoded via postcodes.io.
- 600-leaflet delivery migrated from session_log into deliveries table (Wilmslow Dean Row kickoff, 2026-02-24, Richard & Cahner)
- **T15 completed:** Code review verified all Phase 2-3 flows (reserve, reassign, unassign, complete) call correct RPCs

## Active Tasks

<!-- Multi-agent coordination — see .planning/COORDINATION.md for full protocol.
     REQUIRED: Claim here before making ANY code changes. Remove when done.
     Format: - [AGENT] [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC] -->

None.

## Session Continuity

Last session: 2026-02-25
Stopped at: Phase 5 T2+T3 done (config modal + button). Ready for next task.
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
| T6: Response rate config | ○ Pending | - |
| T7: New campaign UI | ○ Pending | - |
| T7a: Seed test campaign | ○ Pending | - |
| T8: Remove hardcoded STAFF | ○ Pending | - |
