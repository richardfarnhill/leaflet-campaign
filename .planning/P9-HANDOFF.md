# Phase 9 Handoff — Demographic Enrichment (Critical Gaps)

**Date:** 2026-02-26
**Status:** ❌ INCOMPLETE — Gaps identified
**Next Agent:** OpenCode or Claude (whoever takes P9 completion)
**Blocker:** T2b (server-side trigger) MUST be done first

---

## Executive Summary

Phase 9 was marked complete in the previous session, but critical gaps were discovered:

1. **T2b (server-side trigger)** — NOT IMPLEMENTED. Without it, bulk/API demographic enrichment is impossible.
2. **T3 (test enrichment)** — INCOMPLETE. Function exists but never tested with real NOMIS API.
3. **T5 (run backfill)** — INCOMPLETE. Script never tested with real demographic_feedback data.

**Phase cannot be considered complete until all three are done.**

---

## What's Done ✅

| Task | Status | Details |
|------|--------|---------|
| T1 | ✅ Done | `enrichDemographicFeedback()` and `fetchOwnerOccupiedFromNOMIS()` functions added to index.html |
| T2 | ✅ Done | Hooked into UI enquiry save flow (line 1921 in index.html) |
| T4 | ✅ Done | `scripts/backfill_demographics.js` created with correct NOMIS API calls |

**Critical missing pieces:**
- T2b (server-side trigger) — 0% done
- T3 (test enrichment) — 0% done (code review only, no execution test)
- T5 (run backfill) — 0% done (script never ran with real data)

---

## The Problem: Why T2b is Critical

The current implementation has **one enrichment pathway**: browser JS on enquiry save.

**This does NOT handle:**
- Bulk CSV imports directly to `demographic_feedback` table
- Programmatic API inserts
- Historic data backfills
- Any data loaded outside the enquiry modal

Without T2b (server-side trigger), the only way to enrich bulk data is:
1. Query demographic_feedback for NULL owner_occupied_pct
2. Run backfill script manually
3. Hope NOMIS API doesn't fail silently

This is fragile and not production-ready. T2b makes enrichment automatic for ANY source of demographic_feedback data.

---

## What Needs to Happen (Execution Plan)

### Phase: Sequential (T2b must complete before T3/T5)

#### T2b: Server-Side Trigger (BLOCKING)

**Files to modify:** `supabase_schema.sql`

**What to do:**
1. Add this SQL trigger function:
```sql
CREATE OR REPLACE FUNCTION enrich_demographic_feedback()
RETURNS TRIGGER AS $$
DECLARE
  v_pct FLOAT;
  v_response JSONB;
BEGIN
  IF NEW.owner_occupied_pct IS NULL AND NEW.oa21_code IS NOT NULL THEN
    BEGIN
      -- Call NOMIS API via http extension
      v_response := (http_get('https://www.nomisweb.co.uk/api/v01/dataset/NM_2072_1.data.json?geography='||NEW.oa21_code||'&c2021_tenure_9=1001&measures=20301&select=geography_code,obs_value')).content::jsonb;
      -- Parse response and extract percentage value
      v_pct := (v_response->'obs'->0->'obs_value'->>'value')::float;
      NEW.owner_occupied_pct := v_pct;
    EXCEPTION WHEN OTHERS THEN
      -- Log error but don't block insert
      RAISE WARNING 'NOMIS enrichment failed for OA %: %', NEW.oa21_code, SQLERRM;
    END;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_enrich_demographic_on_insert
BEFORE INSERT ON demographic_feedback
FOR EACH ROW
EXECUTE FUNCTION enrich_demographic_feedback();
```

2. Deploy via Supabase MCP (or manual SQL execution)

3. Test with direct INSERT:
```sql
INSERT INTO demographic_feedback (campaign_id, postcode, oa21_code, created_at)
VALUES ('test-campaign', 'WF12 7DX', 'E00000001', NOW())
RETURNING *;
-- Expected: owner_occupied_pct populated automatically
```

**Success criteria:** Direct SQL INSERT to demographic_feedback populates owner_occupied_pct without manual enrichment call.

---

#### T3: Test Complete Enrichment Flow (both UI + bulk)

**Files:** index.html (already has T2), database (needs T2b deployed)

**Part A: Browser-side (UI) test**
1. Open the app
2. Create new instructed enquiry with postcode NOT in route_postcodes (e.g., WF12 7DX from a customer outside your usual territory)
3. Monitor browser console for: `Enriched demographic_feedback XXX: NN% owner-occupied`
4. Verify demographic_feedback table has owner_occupied_pct populated

**Part B: Server-side (bulk) test**
1. Insert 5-10 demographic_feedback rows directly (simulating bulk import):
```sql
INSERT INTO demographic_feedback (campaign_id, postcode, oa21_code, created_at) VALUES
('bulk-test', 'WF14 8NJ', 'E00000002', NOW()),
('bulk-test', 'WF14 8PJ', 'E00000003', NOW()),
('bulk-test', 'WF14 8PR', 'E00000004', NOW()),
('bulk-test', 'WF14 8PS', 'E00000005', NOW()),
('bulk-test', 'WF14 8PT', 'E00000006', NOW());
```

2. Immediately query:
```sql
SELECT id, postcode, oa21_code, owner_occupied_pct FROM demographic_feedback
WHERE campaign_id = 'bulk-test'
ORDER BY created_at;
-- All should have owner_occupied_pct populated
```

3. Verify values are reasonable percentages (0-100)

**Success criteria:** Both pathways work. NOMIS API responds correctly. All test rows enriched.

---

#### T5: Validate & Run Backfill Script

**Files:** `scripts/backfill_demographics.js` (already exists)

**Prerequisites:**
- T3 Part B must have created test data (bulk-test rows)
- T2b trigger must be deployed

**Action:**
1. Run with test data first (dry-run):
```bash
SUPABASE_URL=<your-url> SUPABASE_KEY=<your-key> node scripts/backfill_demographics.js --limit 5 --dry-run
```

2. Verify output shows:
   - Found X rows to backfill
   - Updated rows with percentages
   - No errors

3. Run on full dataset:
```bash
SUPABASE_URL=<your-url> SUPABASE_KEY=<your-key> node scripts/backfill_demographics.js
```

4. Verify with SQL:
```sql
SELECT COUNT(*) as total_rows,
       COUNT(owner_occupied_pct) as enriched_rows,
       COUNT(*) - COUNT(owner_occupied_pct) as still_null
FROM demographic_feedback;
-- still_null should be ~0 (or only non-enrichable rows like invalid OAs)
```

**Success criteria:** Backfill script runs successfully with real data. All enrichable rows get owner_occupied_pct.

---

## Files Modified in This Session

| File | Changes | Status |
|------|---------|--------|
| `.planning/phases/09-demographic-enrichment/09-01-PLAN.md` | Rewrote T2b, T3, T5 to be more rigorous; added success criteria | ✅ Updated |
| `.planning/phases/09-demographic-enrichment/09-01-SUMMARY.md` | Updated execution log to mark T2b/T3/T5 as incomplete; added deviations section | ✅ Updated |
| `.planning/STATE.md` | Phase 9 marked IN PROGRESS; task checklist updated; added handoff section | ✅ Updated |
| `.planning/REQUIREMENTS.md` | DEM-02/DEM-03 status changed to PARTIAL/INCOMPLETE | ✅ Updated |
| `.planning/ROADMAP.md` | Phase 9 status changed to IN PROGRESS with blockers listed | ✅ Updated |

---

## Key Context for Next Agent

### NOMIS API Details
- **Base URL:** `https://www.nomisweb.co.uk/api/v01/dataset/NM_2072_1.data.json`
- **Dataset:** NM_2072_1 (TS054 — Tenure data)
- **Query params:**
  - `geography={oa21_code}` — OA code
  - `c2021_tenure_9=1001` — "Owned" category
  - `measures=20301` — Percentage
  - `select=geography_code,obs_value` — Fields to return
- **Response format:** `data.obs[0].obs_value.value` contains the percentage

### Trigger Implementation Notes
- Supabase must have `http` extension enabled (it usually is)
- Trigger should NOT block insert if NOMIS fails (use EXCEPTION handling)
- If OA is invalid, NOMIS returns empty obs array — trigger should handle gracefully
- No authentication required for NOMIS API (public data)

### Testing Postcodes/OAs
For testing T3 and T5, use these real postcodes with valid OA codes:
- WF12 7DX → E00000001 (example, adjust based on actual data)
- WF14 8NJ, WF14 8PJ, WF14 8PR → valid Tingley OAs
- Use `SELECT DISTINCT oa21_code FROM demographic_feedback LIMIT 5` to get real test data

### Backfill Script Notes
- Script expects environment variables: `SUPABASE_URL`, `SUPABASE_KEY`
- Uses service role key (not anon key) to update rows
- Rate limits to 1 request per 50ms (10 requests per 500ms) to avoid NOMIS throttling
- Already implements NOMIS URL correctly (matches T2 browser version)

---

## What NOT to Do

❌ Don't mark Phase 9 complete until:
- T2b is deployed AND tested with direct INSERT
- T3 runs with real postcode + NOMIS API call succeeds
- T5 runs with real demographic_feedback data (10+ rows enriched)

❌ Don't skip testing with real data (T3/T5 with 0 rows was a false positive)

❌ Don't move to Phase 10 until Phase 9 is fully validated

---

## Timeline Estimate

- **T2b:** 15-20 mins (SQL function + trigger + one test)
- **T3:** 10-15 mins (create UI enquiry, insert test rows, verify DB)
- **T5:** 5-10 mins (run backfill script, verify output)
- **Total:** ~30-45 minutes for complete Phase 9

---

## Sign-Off

**Current state:** CODE REVIEW PASSED, EXECUTION VALIDATION REQUIRED
**Blocker:** T2b MUST be done first
**Next action:** Implement T2b trigger, then T3/T5 in sequence or parallel

All documentation updated as of 2026-02-26. Plans ready for immediate execution.

