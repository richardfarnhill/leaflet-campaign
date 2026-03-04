# Postcode OA Lookup — Load Status & Instructions

## Overview

Table `postcode_oa_lookup` in Supabase stores the mapping of every UK postcode to its
2021 Output Area code (oa21_code). This powers the `trg_enrich_demographic_feedback`
trigger, which auto-populates `oa21_code` (and `owner_occupied_pct`) when an enquiry
postcode is inserted into `demographic_feedback`.

**Supabase project:** tjebidvgvbpnxgnphcrg
**Table:** `postcode_oa_lookup (postcode TEXT PRIMARY KEY, oa21_code TEXT NOT NULL)`
**Source files:** `multi_csv/ONSPD_NOV_2025_UK_{OUTCODE}.csv` (one file per outcode)
**Total files:** 124 (one per outcode area)

---

## How to Load a New Outcode Area

Run this script for each outcode not yet loaded. It is safe to re-run — uses
`ON CONFLICT DO NOTHING`.

**Script:** `scripts/load_postcode_area.py`

```bash
python scripts/load_postcode_area.py WF
python scripts/load_postcode_area.py CH
# etc.
```

**What the script does:**
1. Reads `multi_csv/ONSPD_NOV_2025_UK_{OUTCODE}.csv`
2. Filters to England (E92000001) and Wales (W92000004) only — drops Scotland/NI
3. Extracts columns: `pcds` (col 2) = postcode, `oa21cd` (col 49) = OA21 code
4. Skips rows with blank postcode or oa21_code
5. Inserts in batches of 2000 rows via Supabase MCP execute_sql
6. Prints progress and final count
7. Updates `POSTCODE_LOAD_STATUS.md` — marks outcode as loaded with date + row count

**Column reference (ONSPD Nov 2025):**
- Col 0: `pcd7` — 7-char postcode (padded)
- Col 2: `pcds` — formatted postcode (use this one: "WF12 7DX")
- Col 16: `ctry25cd` — country code (E92000001=England, W92000004=Wales, S92000003=Scotland, N92000002=NI)
- Col 49: `oa21cd` — 2021 Output Area code (e.g. "E00188787")

---

## Loaded Areas

| Outcode | Approx rows | Status | Date loaded |
|---------|-------------|--------|-------------|
| M | ~21,000 | ✓ Done | 2026-02-26 |
| SK | ~11,000 | ✓ Done | 2026-02-26 |
| WF | ~14,000 | ✓ Done | 2026-02-26 |
| WA | ~16,000 | ✓ Done | 2026-02-26 |

## Priority Queue (load next)

| Outcode | Area | Priority |
|---------|------|----------|
| CH | Cheshire (Chester) | High |
| CW | Cheshire (Crewe) | High |
| LS | Leeds | High |
| HD | Huddersfield | High |
| HX | Halifax | High |
| BD | Bradford | High |
| OL | Oldham | High |
| BL | Bolton | High |
| WN | Wigan | High |
| TN | Kent/East Sussex | High |
| EX | Devon | High |
| PR | Preston | Medium |
| BB | Blackburn | Medium |
| FY | Blackpool | Medium |
| LA | Lancaster | Medium |
| YO | York | Medium |
| HG | Harrogate | Medium |
| S | Sheffield | Medium |
| DN | Doncaster | Medium |
| B | Birmingham | Medium |
| CV | Coventry | Medium |
| LE | Leicester | Medium |
| NG | Nottingham | Medium |
| DE | Derby | Medium |
| ST | Stoke | Medium |
| BS | Bristol | Medium |
| CF | Cardiff | Medium |
| SA | Swansea | Medium |
| NP | Newport | Medium |
| E | London E | Low |
| EC | London EC | Low |
| N | London N | Low |
| NW | London NW | Low |
| SE | London SE | Low |
| SW | London SW | Low |
| W | London W | Low |
| WC | London WC | Low |
| (all others) | See file list | Low |

## Not Needed (Scotland / NI / Channel Islands / Isle of Man)

These files exist in multi_csv/ but should NOT be loaded — outside our operating area:

`AB DD DG EH FK G HS IV KA KW KY ML PA PH TD` — Scotland
`BT` — Northern Ireland
`GY JE IM ZE` — Channel Islands / Isle of Man

---

## Verifying Load

After loading, check row count in Supabase:

```sql
SELECT COUNT(*) FROM postcode_oa_lookup;

-- Check a specific postcode:
SELECT * FROM postcode_oa_lookup WHERE postcode = 'WF12 7DX';

-- Check which outcodes are present:
SELECT SUBSTRING(postcode, 1, POSITION(' ' IN postcode) - 1) as outcode,
       COUNT(*) as rows
FROM postcode_oa_lookup
GROUP BY 1
ORDER BY 1;
```

---

## Full End-to-End Flow

Once postcodes are loaded, inserting into `demographic_feedback` with just a postcode
will auto-populate both `oa21_code` AND `owner_occupied_pct` via the trigger:

```sql
-- Example: this will auto-fill oa21_code and owner_occupied_pct
INSERT INTO demographic_feedback (postcode, instructed, instruction_value)
VALUES ('WF12 7DX', true, 1000)
RETURNING postcode, oa21_code, owner_occupied_pct;
```

**Trigger lookup chain (`trg_enrich_demographic_feedback`):**
1. If `oa21_code` already provided → use it directly
2. Else look up postcode in `route_postcodes` → get `oa21_code`
3. If `oa21_code` found → look up `owner_occupied_pct` from `route_postcodes`
4. If nothing found → fields stay NULL (trigger does not block insert)

**Note:** `owner_occupied_pct` is only populated where `route_postcodes` has been
backfilled from NOMIS. For postcodes outside our routes, `owner_occupied_pct` will
be NULL even after trigger runs. `postcode_oa_lookup` resolves the OA code but does
not supply demographic rates — that data lives in `route_postcodes` only.

---

## Notes

- `ON CONFLICT (postcode) DO NOTHING` — safe to re-run any outcode
- `oa21_code` in `demographic_feedback` is nullable — inserts from outside our route areas work fine; fields will just be NULL
- Scotland excluded: OA codes start with S — not in NOMIS TS054 England/Wales dataset