# HANDOFF — Postcode OA Lookup Load

**Date:** 2026-02-26
**From:** Claude Sonnet (context full)
**To:** Next agent (Haiku preferred — this is mechanical work)

---

## What Was Done This Session

1. Created `postcode_oa_lookup` table in Supabase (postcode TEXT PK, oa21_code TEXT)
2. Updated `enrich_demographic_feedback` trigger to fall back to `postcode_oa_lookup`
3. Dropped NOT NULL constraint on `demographic_feedback.oa21_code`
4. Created `scripts/load_postcode_area.py` — prints SQL but does NOT execute it
5. Created `.planning/POSTCODE_LOAD_STATUS.md` — tracks which outcodes are loaded

## CRITICAL: Table is STILL EMPTY

`postcode_oa_lookup` has 0 rows. Nothing has been inserted yet.

---

## Immediate Task: Load WF postcodes

The data is ready. Execute this Python to get the SQL, then run each batch via Supabase MCP.

**Step 1 — Generate rows in Python:**

```python
import csv, json
ENGLAND_WALES = {'E92000001', 'W92000004'}
rows = []
with open('c:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/multi_csv/ONSPD_NOV_2025_UK_WF.csv', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if row[16] not in ENGLAND_WALES: continue
        pc, oa = row[2].strip(), row[49].strip()
        if pc and oa: rows.append((pc.replace("'","''"), oa))
print(len(rows))  # expect ~18,767
```

**Step 2 — For each batch of 2000, build and execute SQL:**

```python
# Build one batch (repeat for i=0,2000,4000,...18000)
batch = rows[0:2000]
vals = ',\n  '.join(f"('{pc}','{oa}')" for pc,oa in batch)
sql = f"INSERT INTO postcode_oa_lookup (postcode, oa21_code) VALUES\n  {vals}\nON CONFLICT (postcode) DO NOTHING;"
# Then call: mcp__claude_ai_Supabase__execute_sql(project_id="tjebidvgvbpnxgnphcrg", query=sql)
```

**Step 3 — Verify:**
```sql
SELECT COUNT(*) FROM postcode_oa_lookup WHERE postcode LIKE 'WF%';
-- expect ~18,767
```

**Step 4 — Test the trigger works:**
```sql
INSERT INTO demographic_feedback (postcode, instructed, instruction_value)
VALUES ('WF12 7DX', true, 1000)
RETURNING postcode, oa21_code, owner_occupied_pct;
-- oa21_code should be populated; owner_occupied_pct may be NULL (that's ok for now)
```

**Step 5 — Update `POSTCODE_LOAD_STATUS.md`:** mark WF as done with row count + date.

---

## Then Load These Outcodes (priority order)

Same pattern for each. CSV files are in:
`c:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/multi_csv/ONSPD_NOV_2025_UK_{OUTCODE}.csv`

Priority: **M, SK, WA, CH, CW, LS, HD, HX, BD, OL, BL, WN, TN, EX**

DO NOT load: AB DD DG EH FK G HS IV KA KW KY ML PA PH TD BT GY JE IM ZE

---

## Supabase MCP Access

Tool: `mcp__claude_ai_Supabase__execute_sql`
If not visible: `ToolSearch query: "+Supabase execute"`
Project ID: `tjebidvgvbpnxgnphcrg`

---

## Key Files

- `scripts/load_postcode_area.py` — generates SQL (prints only, does not execute)
- `.planning/POSTCODE_LOAD_STATUS.md` — tracking doc, update as each outcode loads
- `multi_csv/` — 124 CSV files, one per outcode