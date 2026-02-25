# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.
**Current focus:** Phase 4 - Analytics & Heatmaps (in progress, T1-T12+T14 done, T11/T13 next)

## Current Position

Phase: 4 of 7 (Analytics & Heatmaps)
Plan: 04-01 in progress — T1-T12, T14 complete. T11 (sync review) and T13 (map→card nav) next.
Status: In execution
Last activity: 2026-02-25 — T12 done: all 15 routes now have unique street postcodes geocoded via postcodes.io. GEO-01 satisfied. Map legend added.

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

- T13: Map marker → route card navigation
- T11: App/DB sync review (T12 done, T11 now unblocked)

### Blockers/Concerns

- **T7 error (Claude):** ~~lat/lng inserted as hardcoded approximations~~ — FIXED by T12. All 15 routes now have unique street postcodes geocoded via postcodes.io.
- 600-leaflet delivery migrated from session_log into deliveries table (Wilmslow Dean Row kickoff, 2026-02-24, Richard & Cahner)
- **⚠️ Verification needed before Phase 5:**
  - Phase 1: RLS policies not verified, PostGIS not tested
  - Phase 2: Real-time updates need testing, E2E flow not fully tested
  - Phase 3: Complete flow not tested end-to-end
  - T15 added to verify all previous phases

## Active Tasks

<!-- Multi-agent coordination — see .planning/COORDINATION.md for full protocol.
     REQUIRED: Claim here before making ANY code changes. Remove when done.
     Format: - [AGENT] [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC] -->

- Claude T11 — App/DB sync review — claimed 2026-02-25 11:00 UTC

## Session Continuity

Last session: 2026-02-25
Stopped at: T12 done. T11 (sync review) and T13 (map→card nav) are next — both now unblocked.
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
| T11: App/DB sync review | ○ Pending (wait for T12) | Both |
| T12: Unique postcodes + geocode + legend | ✓ Done | Claude |
| T13: Map → route card navigation | ✓ Done | OC |
| T14: Format Delivery Journal as table | ✓ Done | OC |
| T15: Verify Phases 1-3 implementation | ○ Pending (run after T11-T14) | — |
