# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-25)

**Core value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.
**Current focus:** Phase 5 - Campaign Management (in progress)

## Current Position

Phase: 5 of 7 (Campaign Management)
Plan: 05-01 — All tasks done except T7a (seed test campaign).
Status: Near complete — only T7a outstanding
Last activity: 2026-02-25 — T14 done (restricted area polygons on map)

Progress: [███████████████████░] ~95%

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

- T6: Response rate + case value overrides (CFG-02/04)
- T7a: Seed second campaign for multi-campaign testing

### Blockers/Concerns

- **T15 completed:** Code review verified all Phase 2-3 flows (reserve, reassign, unassign, complete) call correct RPCs
- **DB migrations needed** (run in Supabase SQL editor):
  ```sql
  -- Create restricted_areas table (postcode prefix + radius in miles)
  CREATE TABLE IF NOT EXISTS restricted_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    postcode_prefix VARCHAR(10) NOT NULL,
    radius_miles NUMERIC(5,2) DEFAULT 0,
    label VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
  );
  
  -- Seed default restricted areas
  INSERT INTO restricted_areas (postcode_prefix, radius_miles, label) VALUES
    ('WA14', 0, 'Altrincham'),
    ('WA15', 0, 'Timperley'),
    ('M33', 0, 'Sale'),
    ('SK9', 0, 'Wilmslow');
  
  -- Enable RLS
  ALTER TABLE restricted_areas ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Anyone can read restricted_areas" ON restricted_areas FOR SELECT USING (true);
  CREATE POLICY "Anyone can insert restricted_areas" ON restricted_areas FOR INSERT WITH CHECK (true);
  ```

  -- Add columns to campaigns
  ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS restricted_postcodes text[];
  ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS rate_conservative numeric;
  ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS rate_target numeric;
  ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS rate_optimistic numeric;
  ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS default_case_value numeric;
  ```

## Active Tasks

<!-- Multi-agent coordination — see .planning/COORDINATION.md for full protocol.
     REQUIRED: Claim here before making ANY code changes. Remove when done.
     Format: - [AGENT] [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC] -->

None.

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
| T7a: Seed test campaign | ○ Pending | - |
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
| T1: Enquiry recording modal | ○ Pending | - |
| T2: Enquiry list view | ○ Pending | - |
| T3: Enquiry heatmap overlay | ○ Pending | - |
| T4: Team progress view | ○ Pending | - |
| T5: Leaderboards | ○ Pending | - |
| T6: Add route creation UI | ○ Pending | - |
