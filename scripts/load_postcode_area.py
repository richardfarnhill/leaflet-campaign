"""
Load a postcode outcode area into Supabase postcode_oa_lookup table.

Usage:
    python scripts/load_postcode_area.py WF
    python scripts/load_postcode_area.py CH
    python scripts/load_postcode_area.py LS

Source: multi_csv/ONSPD_NOV_2025_UK_{OUTCODE}.csv
Target: Supabase table postcode_oa_lookup (postcode TEXT PK, oa21_code TEXT)

COLUMN REFERENCE (ONSPD Nov 2025):
  Col  2: pcds     — formatted postcode e.g. "WF12 7DX"
  Col 16: ctry25cd — country code
  Col 49: oa21cd   — 2021 Output Area code

COUNTRY FILTER (England & Wales only):
  E92000001 = England
  W92000004 = Wales
  (Scotland S92000003 and NI N92000002 are excluded)

DO NOT LOAD: AB DD DG EH FK G HS IV KA KW KY ML PA PH TD (Scotland)
             BT (Northern Ireland), GY JE IM ZE (Channel Islands / IoM)

Uses Supabase MCP tool: mcp__claude_ai_Supabase__execute_sql
Project ID: tjebidvgvbpnxgnphcrg
"""

import csv
import sys
import os

SUPABASE_PROJECT = "tjebidvgvbpnxgnphcrg"
ENGLAND_WALES = {"E92000001", "W92000004"}
BATCH_SIZE = 2000  # rows per INSERT statement

SCOTLAND_NI = {"AB","DD","DG","EH","FK","G","HS","IV","KA","KW","KY","ML","PA","PH","TD","BT","GY","JE","IM","ZE"}

def load_outcode(outcode: str):
    outcode = outcode.upper().strip()

    if outcode in SCOTLAND_NI:
        print(f"ERROR: {outcode} is Scotland/NI/CI — do not load.")
        sys.exit(1)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    csv_path = os.path.join(project_root, "multi_csv", f"ONSPD_NOV_2025_UK_{outcode}.csv")

    if not os.path.exists(csv_path):
        print(f"ERROR: File not found: {csv_path}")
        sys.exit(1)

    print(f"Reading {csv_path}...")
    rows = []
    with open(csv_path, encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)  # skip header
        for row in reader:
            if row[16] not in ENGLAND_WALES:
                continue
            postcode = row[2].strip()
            oa21 = row[49].strip()
            if not postcode or not oa21:
                continue
            # Escape single quotes in postcode (safety)
            postcode = postcode.replace("'", "''")
            rows.append((postcode, oa21))

    print(f"Found {len(rows):,} England/Wales rows for {outcode}")

    if not rows:
        print("Nothing to insert.")
        return

    # Build INSERT statements in batches
    total_batches = (len(rows) + BATCH_SIZE - 1) // BATCH_SIZE
    print(f"Inserting in {total_batches} batches of up to {BATCH_SIZE} rows...")
    print()
    print("=" * 60)
    print("INSTRUCTIONS FOR CLAUDE / HAIKU:")
    print("Execute each SQL block below using:")
    print("  mcp__claude_ai_Supabase__execute_sql")
    print(f"  project_id: {SUPABASE_PROJECT}")
    print("=" * 60)
    print()

    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i+BATCH_SIZE]
        vals = ",\n  ".join(f"('{pc}','{oa}')" for pc, oa in batch)
        sql = f"INSERT INTO postcode_oa_lookup (postcode, oa21_code) VALUES\n  {vals}\nON CONFLICT (postcode) DO NOTHING;"
        batch_num = i // BATCH_SIZE + 1
        print(f"-- BATCH {batch_num}/{total_batches} ({len(batch)} rows)")
        print(sql)
        print()

    print(f"-- VERIFY: run this after all batches:")
    print(f"SELECT COUNT(*) FROM postcode_oa_lookup WHERE postcode LIKE '{outcode}%';")
    print()
    print(f"-- UPDATE POSTCODE_LOAD_STATUS.md: mark {outcode} as done with row count and date.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python load_postcode_area.py <OUTCODE>")
        print("Example: python load_postcode_area.py WF")
        sys.exit(1)
    load_outcode(sys.argv[1])
