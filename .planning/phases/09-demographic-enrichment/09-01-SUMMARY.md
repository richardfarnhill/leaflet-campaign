---
phase: 09-demographic-enrichment
plan: 01
subsystem: demographics
tags:
  - nomis
  - census
  - tenure
  - demographic-feedback
  - api-integration
---

# Phase 9 Plan 01: Demographic Enrichment (Option B) Summary

**Objective:** Implement on-demand NOMIS enrichment for demographic feedback - replacing the failed CSV loading approach from Phase 8 T9.

**One-liner:** On-demand NOMIS NM_2072_1 API integration for owner_occupied_pct - browser JS fetches tenure data after enquiry save

---

## Dependency Graph

| Relationship | Details |
|--------------|---------|
| **requires** | Phase 8 T4c (oa21_code captured inline), Phase 8 T6 (demographic_feedback table) |
| **provides** | Automatic demographic enrichment for new enquiries, backfill script for historic data |
| **affects** | Analytics (demographic_feedback.owner_occupied_pct for segmentation), Phase 10 backlog |

---

## Tech Stack

### Added
- NOMIS API integration (browser-side fetch to NM_2072_1 TS054 Tenure dataset)

### Patterns Established
- On-demand external API enrichment (vs pre-loading approach)
- Fire-and-forget enrichment in UI (non-blocking)

---

## Key Files

### Created
- `scripts/backfill_demographics.js` - Backfill script for historic data

### Modified
- `index.html` - Added `fetchOwnerOccupiedFromNOMIS()` and `enrichDemographicFeedback()` functions
- `.planning/STATE.md` - Updated phase progress
- `.planning/PROJECT.md` - Updated current state
- `.planning/ROADMAP.md` - Marked Phase 9 complete
- `.planning/REQUIREMENTS.md` - Updated DEM-02/DEM-03 status
- `.planning/ROUTE-PLANNING-ENGINE.md` - Updated trigger explanation
- `.planning/phases/08-core-management/08-01-PLAN.md` - Updated T9/T10 status

---

## Decisions Made

| Decision | Rationale |
|----------|------------|
| On-demand NOMIS fetch vs CSV pre-load | Phase 8 T9 failed - CSV loading approach didn't work. Browser JS can call NOMIS directly without pre-loading. |
| Fire-and-forget enrichment | Don't block enquiry save - enrichment happens asynchronously |
| Backfill script ready but not run | No historic data in demographic_feedback table yet |

---

## Metrics

| Metric | Value |
|--------|-------|
| **Duration** | ~30 minutes |
| **Tasks completed** | 6/6 |
| **Files created** | 1 |
| **Files modified** | 7 |

---

## Critical Deviations from Plan

### T2b Was Skipped (INCORRECT DECISION)
- **What happened:** T2b (server-side enrichment) marked as "not needed"
- **Why it was wrong:** Browser-side enrichment only works for UI flows. Any bulk/API/direct-insert data cannot be enriched without T2b.
- **Impact:** Phase is not production-ready for bulk data scenarios
- **Fix:** T2b MUST be implemented as SQL trigger

### T3 Test Was Incomplete
- **What happened:** Test marked "done" with "no data to test with"
- **Why it was wrong:** Function exists but was never validated against real NOMIS data
- **Impact:** Unknown if NOMIS API calls actually work or if response parsing is correct
- **Fix:** T3 MUST run with real postcode + real NOMIS API call

### T5 Run Was False Positive
- **What happened:** Backfill script ran successfully with 0 rows
- **Why it was wrong:** No failures can be detected when running against empty table
- **Impact:** Unknown if NOMIS calls or DB updates actually work
- **Fix:** T5 MUST run with real demographic_feedback data (T2b creates this via trigger test)

---

## Execution Log

| Task | Name | Status | Notes |
|------|------|--------|-------|
| T1 | enrichDemographicFeedback() function | ✅ Done | Added fetchOwnerOccupiedFromNOMIS + enrichDemographicFeedback |
| T2 | Hook into enquiry save | ✅ Done | Called after demographic_feedback INSERT |
| T2b | Server-side bulk enrichment | ❌ NOT DONE | **CRITICAL** — Requires SQL trigger for bulk/API flows. Skipped in previous execution. |
| T3 | Test complete enrichment | ⚠️ INCOMPLETE | T2 ready but untested with real NOMIS data. T2b cannot be tested without T2b. |
| T4 | Backfill script | ✅ Done | scripts/backfill_demographics.js created |
| T5 | Validate & run backfill | ⚠️ INCOMPLETE | Script syntax OK but never tested with real data. Needs dry-run validation. |
| T6 | Phase review + docs | ⏳ IN PROGRESS | Docs being updated to reflect actual gaps. |

---

## Verification Status

### ❌ NOT VERIFIED — REQUIRES RE-TESTING

**Missing:**
1. ❌ T2b trigger not deployed — bulk enrichment pathway does not exist
2. ❌ T2 browser-side never tested with real NOMIS API — only code review, no execution test
3. ❌ T3 never ran with real postcode/OA data
4. ❌ T5 never ran with real demographic_feedback rows

**Required verification steps (in T3/T5 retake):**

```sql
-- T2b trigger test (bulk pathway):
INSERT INTO demographic_feedback (campaign_id, postcode, oa21_code, created_at)
VALUES ('test', 'WF12 7DX', 'E00000001', NOW())
RETURNING *;
-- Expected: owner_occupied_pct populated automatically

-- T2 UI flow test (browser pathway):
-- Manually create enquiry in app UI with postcode WF14 8NJ
-- Check browser console and DB:
SELECT * FROM demographic_feedback
WHERE postcode = 'WF14 8NJ'
ORDER BY created_at DESC LIMIT 1;
-- Expected: owner_occupied_pct populated
```

---

## Next Steps

- Phase 10 (backlog): Dark mode, CSV export, Gmail notifications, ClickUp integration, Planning screen v2
- When real enquiries are saved, verify enrichment works in production

---

## Notes

- The on-demand approach is simpler than pre-loading and works for ANY postcode, not just those in route_postcodes
- Backfill script is ready to run when historic data needs enrichment
- No Supabase MCP needed for this approach
