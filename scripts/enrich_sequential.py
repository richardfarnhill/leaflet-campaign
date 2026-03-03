#!/usr/bin/env python3
"""
Sequential street enrichment for zero-street routes.
Runs strictly 1 request/sec to stay under Nominatim rate limit.
"""

import re
import sys
import time
import requests

with open('config.js') as f:
    content = f.read()

SB_URL = re.search(r'SUPABASE_URL\s*:\s*["\']([^"\']+)["\']', content).group(1)
SB_KEY = re.search(r'SUPABASE_KEY\s*:\s*["\']([^"\']+)["\']', content).group(1)

CAMPAIGN_ID = '10c1ee37-3e33-48b8-85ed-c5da41771b18'
HEADERS = {'apikey': SB_KEY, 'Authorization': f'Bearer {SB_KEY}', 'Content-Type': 'application/json'}
NOM_HEADERS = {'User-Agent': 'LeafletCampaignTracker/1.0 (contact: richardfarnhill@yahoo.com)'}

def sb_get(path):
    r = requests.get(f'{SB_URL}/rest/v1/{path}', headers=HEADERS)
    r.raise_for_status()
    return r.json()

def sb_patch(table, row_id, data):
    r = requests.patch(
        f'{SB_URL}/rest/v1/{table}?id=eq.{row_id}',
        headers=HEADERS,
        json=data
    )
    r.raise_for_status()

# Fetch zero-street routes
routes = sb_get(f'target_areas?select=id,area_name,streets&campaign_id=eq.{CAMPAIGN_ID}&order=area_name')
zero_routes = [r for r in routes if not (r.get('streets') or [])]

print(f'Found {len(zero_routes)} zero-street routes to enrich')
print()

last_request = 0.0
DELAY = 1.5  # seconds between requests — slightly over 1/sec to be safe

def nominatim_reverse(lat, lng):
    global last_request
    elapsed = time.time() - last_request
    if elapsed < DELAY:
        time.sleep(DELAY - elapsed)

    url = f'https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json'
    try:
        last_request = time.time()
        r = requests.get(url, headers=NOM_HEADERS, timeout=10)
        if r.status_code == 429:
            print('    [RATE LIMIT] 429 received, waiting 10s...')
            time.sleep(10)
            last_request = time.time()
            r = requests.get(url, headers=NOM_HEADERS, timeout=10)
        r.raise_for_status()
        data = r.json()
        addr = data.get('address', {})
        return addr.get('road') or addr.get('residential')
    except Exception as e:
        print(f'    [WARN] Nominatim error: {e}')
        return None

total_enriched = 0

for route in zero_routes:
    route_id = route['id']
    route_name = route['area_name']

    # Fetch postcodes for this route
    postcodes = sb_get(f'route_postcodes?select=postcode,lat,lng&target_area_id=eq.{route_id}')

    if not postcodes:
        print(f'  SKIP {route_name}: no postcodes')
        continue

    print(f'  {route_name}: {len(postcodes)} postcodes...')
    streets = set()

    for pc in postcodes:
        lat = pc.get('lat')
        lng = pc.get('lng')
        postcode = pc.get('postcode', '?')

        if lat is None or lng is None:
            continue

        street = nominatim_reverse(lat, lng)
        if street:
            streets.add(street)
            print(f'    {postcode} -> {street}')
        else:
            print(f'    {postcode} -> (no road)')

    sorted_streets = sorted(list(streets))
    sb_patch('target_areas', route_id, {'streets': sorted_streets})
    print(f'  OK {route_name}: {len(sorted_streets)} streets written: {sorted_streets[:3]}{"..." if len(sorted_streets) > 3 else ""}')
    print()
    total_enriched += 1

print(f'Done. {total_enriched}/{len(zero_routes)} routes enriched.')
