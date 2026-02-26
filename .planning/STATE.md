# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.
**Current focus:** Phase 6 in progress - route creation. Phase 7 next (OpenCode).

## Current Position

Phase: 6 of 9 (Enquiry & Team)
Plan: 06-01 — In progress
Status: In Progress — T08 (Route creation) by Claude, T07 ready for OpenCode
Last activity: 2026-02-25 — Campaign data isolation, leaderboards, enquiry fixes

Progress: [████████████░░░░░░░░░░] ~56% (6 of 9 phases)

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

- Claude [06-T08] — Route creation UI — claimed 2026-02-25 22:XX UTC

## Session Continuity

Last session: 2026-02-25
Stopped at: T06 (Team progress view) complete + enquiry_date bug fix
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
| T8: Route creation UI | ○ In Progress - Claude | Claude |
| T9: Route deletion UI | ○ Pending | - |
| T10: Phase review + gap identification | ○ Pending | - |

## Phase 7 Task Checklist

| Task | Status | Agent |
|------|--------|-------|
| T1: Route card details - street names, map boundary | ○ Pending | - |
| T2: Route deletion UI | ○ Pending | - |
| T3: RLS policies verification | ○ Pending | - |
| T4: Route completion - explicit leaflet count + rolling adjustment | ○ Pending | - |
| T5: Security - move credentials to config.js | ✓ Done | OC |
| T6: DB-driven Summary Bar fix (CFG-03) | ○ Pending | |
| T7: Phase review | ○ Pending | - |

## Phase 8 Task Checklist

| Task | Status | Notes |
|------|--------|-------|
| T1: Create campaign - enhance with route creation questions | ○ Pending | Review after P7 |
| T2: Global exclusion areas review | ○ Pending | Clarify DB state |
| T3: Prompt new route when 500 houses short | ○ Pending | |
| T4: Auto-assign enquiries to routes | ○ Pending | Critical for leaderboard |
| T5: API endpoints (Supabase) | ○ Pending | |
| T6: Demographic feedback table from enquiries | ○ Pending | |

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
