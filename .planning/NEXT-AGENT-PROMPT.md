# Next Agent Prompt — Phase 9 Completion (T2b + T3 + T5)

## Context
Phase 9 (Demographic Enrichment) was marked complete but critical gaps were discovered during review:
1. **T2b (server-side trigger)** — NOT IMPLEMENTED (BLOCKER)
2. **T3 (test enrichment)** — NOT VALIDATED with real data
3. **T5 (run backfill)** — NOT VALIDATED with real data

See `.planning/P9-HANDOFF.md` for full details. This prompt is the summary.

---

## Your Task

**Complete Phase 9 by finishing T2b + T3 + T5 with real data validation.**

You must do them in this order:
1. **T2b first** (it's a blocker)
2. **T3 next** (test both UI + bulk enrichment)
3. **T5 last** (validate backfill script with real data)

---

## T2b: Server-Side Trigger (BLOCKING)

**What:** Add SQL trigger to `demographic_feedback` that auto-enriches with NOMIS data when ANY new row is inserted (not just UI enquiries).

**Why:** Browser JS only enriches UI enquiries. Bulk/API inserts skip enrichment. T2b makes it automatic for all sources.

**How:**
1. Open `supabase_schema.sql`
2. Add trigger function + trigger (see P9-HANDOFF.md for SQL)
3. Deploy via Supabase MCP or manual SQL execution
4. Test with:
```sql
INSERT INTO demographic_feedback (campaign_id, postcode, oa21_code, created_at)
VALUES ('test', 'WF12 7DX', 'E00000001', NOW())
RETURNING *;
-- owner_occupied_pct should be populated automatically
```

**Success:** Direct SQL INSERT populates owner_occupied_pct without any manual call.

---

## T3: Test Enrichment (UI + Bulk)

**Prerequisites:** T2b deployed

**Part A — UI enrichment (browser path):**
1. Open app
2. Create new instructed enquiry with postcode NOT in route_postcodes (e.g., WF12 7DX)
3. Check browser console for: `Enriched demographic_feedback XXX: NN% owner-occupied`
4. Verify demographic_feedback table has the row with owner_occupied_pct populated

**Part B — Bulk enrichment (direct SQL path):**
1. Insert 5-10 test rows directly:
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
WHERE campaign_id = 'bulk-test';
-- All should have owner_occupied_pct populated (check values are 0-100%)
```

**Success:** Both UI and bulk paths work. NOMIS API returns data. All rows enriched.

---

## T5: Validate Backfill Script

**Prerequisites:** T2b deployed, T3 Part B test data exists

**Action:**
1. Run script with test data:
```bash
SUPABASE_URL=<your-url> SUPABASE_KEY=<your-key> node scripts/backfill_demographics.js --limit 5 --dry-run
```

2. Verify output shows rows enriched (no errors)

3. Run on full dataset:
```bash
SUPABASE_URL=<your-url> SUPABASE_KEY=<your-key> node scripts/backfill_demographics.js
```

4. Verify with SQL:
```sql
SELECT COUNT(*) as total_rows,
       COUNT(owner_occupied_pct) as enriched_rows
FROM demographic_feedback;
-- enriched_rows should ~equal total_rows
```

**Success:** Backfill script runs without error. All enrichable rows get owner_occupied_pct.

---

## When You're Done

1. **Commit your work** with message like:
   ```
   feat(09-02): complete phase 9 — T2b trigger + T3/T5 validation
   ```

2. **Update docs** (if needed):
   - Mark T2b/T3/T5 as ✅ Done in `.planning/STATE.md`
   - Update Phase 9 status to ✅ COMPLETE in `.planning/ROADMAP.md`
   - Update REQUIREMENTS.md DEM-02/DEM-03 to ✅ DONE

3. **Remove this handoff file** (optional cleanup):
   ```bash
   rm .planning/P9-HANDOFF.md .planning/NEXT-AGENT-PROMPT.md
   ```

---

## Key Files

- `.planning/P9-HANDOFF.md` — Full details, NOMIS API spec, code snippets
- `.planning/phases/09-demographic-enrichment/09-01-PLAN.md` — Updated plan with T2b/T3/T5 details
- `supabase_schema.sql` — Where to add T2b trigger
- `index.html` — Already has T2 (browser JS enrichment)
- `scripts/backfill_demographics.js` — Already exists, just needs testing

---

## Quick Checklist

- [ ] T2b trigger implemented in supabase_schema.sql
- [ ] T2b tested with direct SQL INSERT
- [ ] T3 Part A (UI enquiry) created and verified
- [ ] T3 Part B (bulk test rows) created and verified
- [ ] T5 dry-run successful
- [ ] T5 full run successful
- [ ] Docs updated
- [ ] Commit created
- [ ] Phase 9 marked complete in STATE.md + ROADMAP.md

---

## Questions?

See `.planning/P9-HANDOFF.md` for:
- NOMIS API details
- Trigger implementation notes
- Testing postcodes
- Rate limiting info
- What NOT to do

**Good luck!** Phase 9 is 30-45 minutes of straightforward implementation + testing.

