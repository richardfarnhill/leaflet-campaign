# Phase 5 Context: Campaign Management

**Status:** Ready to plan
**Goal:** Users can switch between campaigns and configure campaign settings

---

## What We're Building

Phase 5 adds campaign management capabilities:
1. Campaign switching via dropdown (already partially implemented)
2. Campaign config UI - edit total leaflets, team members, dates
3. Aggregated data view across all campaigns
4. Response rate configuration for revenue projections
5. (DEM-01) Demographic filtering - lower priority, may defer

---

## Requirements

- **CMP-01:** Campaign Switching — switch between campaigns via dropdown
- **CMP-02:** Aggregated Data View — totals across all campaigns
- **CFG-01:** Campaign Config UI — edit total leaflets, team members, dates
- **CFG-02:** Response Rate Config — configure 0.25%, 0.5%, 0.75% scenarios
- **DEM-01:** Custom Demographic Rules — filter areas by tenure/household type (defer?)

---

## Dependencies

- Phase 1 - campaigns, team_members tables exist
- Phase 4 - analytics dashboard structure in place

---

## Technical Notes

- Single-file app (index.html), no build step
- campaigns table: id, name, target_leaflets, start_date, end_date, is_active, created_at
- campaign_members table: campaign_id, team_member_id (many-to-many)
- Current campaign selector already exists in header
- Need to add: config panel/modal, aggregated stats view

---

## Current State

- Campaign selector exists in header (works for switching)
- Hardcoded values: 20000 leaflets, team names in STAFF array
- Analytics shows completion rate vs hardcoded 20000

---

## Questions

1. Is DEM-01 (demographic filtering) needed now or later?
2. Should campaign config be a modal or separate page?
3. How to handle aggregated view - new tab/section or summary bar?
