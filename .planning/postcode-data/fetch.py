import urllib.parse
import json
import time
import sys

OUTDIR = "/mnt/c/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/.planning/postcode-data"

routes = [
    ("16185256-03d0-4df3-b9a2-06998ec18e5c", "SK8 7", "SK8"),
    ("15a27997-d987-4c23-8c05-be057aa9e805", "SK7 1", "SK7"),
    ("afff81f4-dd25-4030-b2d1-99ab20eff815", "M20 2", "M20"),
    ("f3467cf7-5479-49a5-81b7-f9373e325b80", "M20 6", "M20"),
    ("738b477f-5fee-4d0b-8b50-803c097c4a79", "M20 6", "M20"),
    ("a11d7d11-cb92-4ac2-9c51-6bb295c1f250", "SK9 3", "SK9"),
    ("9376953a-f721-4768-9ea4-e262f61b421c", "WA16 7", "WA16"),
    ("74bebda7-a421-45af-80ef-f696fbd351ff", "WA13 0", "WA13"),
    ("5be4e466-5482-4365-8a93-1dc43b32a9a0", "SK9 3", "SK9"),
    ("74708d2b-df60-4e64-94e2-ecac0a749851", "SK12 1", "SK12"),
    ("725c685c-84d4-4550-9672-64e742cd8642", "SK8 7", "SK8"),
    ("2d9f9b8e-a4ab-40f3-832e-478e5c596825", "SK9 2", "SK9"),
    ("8f55161f-e9b3-4c3f-9a0d-49c785f09d0e", "SK9 2", "SK9"),
    ("b340b683-683a-46cd-8f78-edfffcbc9ac8", "SK9 5", "SK9"),
    ("31444585-e978-40c2-9b87-374ec5e38476", "SK9 5", "SK9"),
]

sector_cache = {}

def fetch_url(url):
    import subprocess
    result = subprocess.run(["curl", "-s", "--max-time", "15", url], capture_output=True, text=True)
    return json.loads(result.stdout)

def fetch_sector_postcodes(sector):
    if sector in sector_cache:
        return sector_cache[sector]

    all_postcodes = []
    page = 1

    while True:
        encoded = urllib.parse.quote(sector)
        url = f"https://api.postcodes.io/postcodes?q={encoded}&limit=100&page={page}"
        data = fetch_url(url)
        results = data.get("result") or []

        for r in results:
            all_postcodes.append({
                "postcode": r.get("postcode"),
                "longitude": r.get("longitude"),
                "latitude": r.get("latitude"),
                "oa21_code": (r.get("codes") or {}).get("oa21"),
            })

        if len(results) < 100:
            break

        page += 1
        time.sleep(0.1)

    sector_cache[sector] = (all_postcodes, page)
    return all_postcodes, page

print(f"{'route_id':<40} {'sector':<8} {'pages':>6} {'postcodes':>10}")
print("-" * 70)
sys.stdout.flush()

for route_id, sector, outcode in routes:
    postcodes, total_pages = fetch_sector_postcodes(sector)

    records = [
        {
            "target_area_id": route_id,
            "postcode": p["postcode"],
            "postcode_sector": sector,
            "outcode": outcode,
            "oa21_code": p["oa21_code"],
            "lat": p["latitude"],
            "lng": p["longitude"],
        }
        for p in postcodes
    ]

    out_path = f"{OUTDIR}/route_{route_id}_full.json"
    with open(out_path, "w") as f:
        json.dump(records, f, indent=2)

    print(f"{route_id:<40} {sector:<8} {total_pages:>6} {len(postcodes):>10}")
    sys.stdout.flush()

print("\nDone.")