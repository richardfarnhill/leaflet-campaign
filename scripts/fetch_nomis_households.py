"""
Fetch NOMIS household counts for all OA21 codes in the 14k_Feb_2026 campaign.

Uses NM_2072_1 (TS054 Tenure) — same dataset as owner_occupied_pct enrichment.
  - c2021_tenure_9=0  = "Total: All households"
  - measures=20100    = count (not percent)

Steps:
  1. Bulk-resolve OA21 alpha codes to NOMIS numeric IDs via NM_2072_1 def.sdmx.json
  2. Batch-fetch household counts
  3. Output JSON: { "E00025680": 124, ... }

Output goes to stdout. Errors go to stderr.
Run: python scripts/fetch_nomis_households.py > /tmp/household_counts.json
"""

import requests
import json
import time
import sys

import urllib3
urllib3.disable_warnings()

# All 315 unique OA21 codes from route_postcodes for campaign 10c1ee37-...
OA_CODES = [
    "E00025680","E00025691","E00025692","E00025693","E00025695","E00025697","E00025699",
    "E00025700","E00025701","E00025703","E00025704","E00025705","E00025706","E00025707",
    "E00025708","E00025709","E00025711","E00025712","E00025715","E00025716","E00025717",
    "E00025718","E00025719","E00025720","E00025907","E00025919","E00025921","E00025922",
    "E00025926","E00025927","E00025928","E00026169","E00026170","E00026171","E00026172",
    "E00026174","E00026175","E00026176","E00026177","E00026178","E00026179","E00026180",
    "E00026181","E00026182","E00026183","E00026184","E00026185","E00026186","E00026187",
    "E00026188","E00026189","E00026190","E00026191","E00026192","E00026193","E00026194",
    "E00026195","E00026196","E00026197","E00026198","E00026199","E00026200","E00026201",
    "E00026203","E00026204","E00026207","E00026208","E00026209","E00026720","E00026721",
    "E00026723","E00026886","E00026888","E00026889","E00026890","E00026891","E00029235",
    "E00029281","E00029313","E00029314","E00029315","E00029316","E00029317","E00029318",
    "E00029321","E00029322","E00029323","E00029324","E00029327","E00029328","E00029329",
    "E00029330","E00029331","E00029332","E00029333","E00029334","E00029339","E00029340",
    "E00029342","E00029345","E00029349","E00029351","E00029354","E00029355","E00029357",
    "E00030000","E00030001","E00030005","E00030006","E00030007","E00030008","E00030009",
    "E00030011","E00030022","E00030027","E00030029","E00030030","E00030032","E00030033",
    "E00030034","E00030035","E00030036","E00030037","E00030038","E00030039","E00030040",
    "E00030041","E00030042","E00030043","E00030044","E00030045","E00063111","E00063118",
    "E00063122","E00063123","E00063126","E00063127","E00063128","E00063129","E00063130",
    "E00063131","E00063132","E00063133","E00063134","E00063135","E00063136","E00063137",
    "E00063138","E00063139","E00063140","E00063141","E00063142","E00093761","E00093765",
    "E00093766","E00093767","E00093768","E00093769","E00093770","E00093771","E00093772",
    "E00093773","E00093774","E00093775","E00093776","E00093778","E00093779","E00093780",
    "E00093781","E00093782","E00093804","E00093806","E00093823","E00093824","E00093825",
    "E00093826","E00093827","E00093828","E00093829","E00093830","E00093831","E00093832",
    "E00093834","E00093835","E00093836","E00093837","E00093838","E00093839","E00093840",
    "E00093841","E00093842","E00093843","E00093844","E00093845","E00093846","E00093847",
    "E00093848","E00093849","E00093850","E00093851","E00093852","E00093867","E00093870",
    "E00093871","E00093872","E00093873","E00093874","E00093875","E00093876","E00093877",
    "E00093879","E00093880","E00093881","E00093882","E00093884","E00093886","E00093914",
    "E00093920","E00093934","E00093942","E00094116","E00094117","E00094125","E00094126",
    "E00094127","E00094128","E00094129","E00094130","E00094131","E00094132","E00094133",
    "E00094134","E00094135","E00094136","E00094139","E00094141","E00094142","E00094143",
    "E00094144","E00094145","E00094146","E00094147","E00094148","E00094149","E00094151",
    "E00094158","E00094159","E00094160","E00094161","E00094162","E00094163","E00094164",
    "E00094165","E00094166","E00094167","E00094168","E00094169","E00094170","E00094171",
    "E00094172","E00094173","E00094174","E00094175","E00094176","E00094177","E00094178",
    "E00094179","E00094180","E00094181","E00094182","E00094183","E00094184","E00094185",
    "E00094186","E00094187","E00094188","E00094189","E00094190","E00094191","E00094192",
    "E00094193","E00094194","E00094195","E00094196","E00094197","E00094198","E00094199",
    "E00094200","E00094201","E00094202","E00094203","E00094204","E00094205","E00094210",
    "E00094227","E00168591","E00174341","E00174342","E00174371","E00174403","E00175884",
    "E00175888","E00175889","E00176088","E00177714","E00177716","E00177738","E00177739",
    "E00177747","E00180886","E00180901","E00184563","E00184638","E00188777","E00188790",
]

NOMIS_BASE = "https://www.nomisweb.co.uk/api/v01"
DATA_BATCH = 100  # alpha OA codes per data.json call — alpha codes work directly, no ID resolution needed


def fetch_household_counts(oa_codes):
    """Fetch total household counts for OA21 alpha codes via NM_2072_1.

    Alpha codes (e.g. E00025680) work directly in the data endpoint.
    No two-step numeric ID resolution required.

    c2021_tenure_9=0 = "Total: All households"
    measures=20100   = count (not percent)
    """
    joined = ",".join(oa_codes)
    url = (
        f"{NOMIS_BASE}/dataset/NM_2072_1.data.json"
        f"?geography={joined}"
        f"&c2021_tenure_9=0"
        f"&measures=20100"
        f"&select=geography_code,obs_value"
    )
    r = requests.get(url, verify=False, timeout=30)
    r.raise_for_status()
    data = r.json()

    counts = {}
    for obs in data.get("obs", []):
        geo_code = obs.get("geography", {}).get("geogcode")  # alpha "E00025680"
        count = obs.get("obs_value", {}).get("value")
        if geo_code and count is not None:
            counts[geo_code] = int(count)
    return counts


def main():
    print(f"Fetching household counts for {len(OA_CODES)} OA21 codes...", file=sys.stderr)
    alpha_to_count = {}

    for i in range(0, len(OA_CODES), DATA_BATCH):
        batch = OA_CODES[i:i + DATA_BATCH]
        end = min(i + DATA_BATCH, len(OA_CODES))
        print(f"  Batch {i+1}-{end}...", file=sys.stderr)
        try:
            counts = fetch_household_counts(batch)
            alpha_to_count.update(counts)
            print(f"    Got {len(counts)}/{len(batch)}", file=sys.stderr)
        except Exception as e:
            print(f"  ERROR: {e}", file=sys.stderr)
        time.sleep(0.3)

    missed = set(OA_CODES) - set(alpha_to_count.keys())
    print(f"\nDone: {len(alpha_to_count)}/{len(OA_CODES)} fetched, {len(missed)} missed", file=sys.stderr)
    if missed:
        print(f"Missed OAs: {sorted(missed)}", file=sys.stderr)

    print(json.dumps(alpha_to_count, indent=2))


if __name__ == "__main__":
    main()
