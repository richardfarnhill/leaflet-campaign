#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Street Name Enrichment — OS Open Names Source (resolves OI-01)

Uses Ordnance Survey Open Names dataset to populate target_areas.streets
for all postcodes in a route.

Method: Spatial proximity matching
- For each postcode in route, find all street names within ~500m radius
- Deduplicate and sort
- Update target_areas.streets array

Prerequisites:
- OS Open Names CSV downloaded from https://osdatahub.os.uk/downloads/open/OpenNames
- Extract to: scripts/data/os-open-names.csv (or use API via OS Names API)
- Supabase client: `pip install supabase`
"""

import json
import requests
import sys
from pathlib import Path

# Supabase config
SUPABASE_URL = "https://xxxxxx.supabase.co"  # Will be set from config.js
SUPABASE_KEY = "xxxxxx"  # Will be set from config.js

class OSNamesStreetLookup:
    """
    Enrich routes with street names using OS Open Names dataset.
    Two modes:
    1. Local CSV (fastest, requires pre-download)
    2. OS Names API (no download, slower, API-dependent)
    """

    def __init__(self, csv_path=None, use_api=False):
        """
        Initialize lookup engine.

        Args:
            csv_path: Path to OS Open Names CSV file (optional)
            use_api: If True, use OS Names API instead of CSV
        """
        self.use_api = use_api
        self.csv_data = None
        self.api_cache = {}  # Cache API results

        if csv_path and Path(csv_path).exists():
            self._load_csv(csv_path)
            print(f"✓ Loaded OS Open Names from CSV: {csv_path}")
        elif not use_api:
            print("⚠ CSV not found. Switching to API mode.")
            self.use_api = True

    def _load_csv(self, csv_path):
        """Load OS Open Names CSV and build spatial index."""
        import pandas as pd
        from scipy.spatial import KDTree

        df = pd.read_csv(csv_path)

        # Filter to street records (class contains 'road', 'street', 'lane', etc.)
        self.csv_data = df[
            df['class'].str.contains(
                'road|street|lane|avenue|drive|close|grove|park|place|terrace|square|court|crescent|heights|walk',
                case=False,
                na=False,
                regex=True
            )
        ].copy()

        # Build spatial index
        coords = self.csv_data[['latitude', 'longitude']].values
        self.tree = KDTree(coords)
        self.indexed_streets = self.csv_data

        print(f"  Built spatial index: {len(self.csv_data)} street records indexed")

    def get_streets_for_postcodes(self, postcodes_with_coords):
        """
        Get all street names near a list of postcodes.

        Args:
            postcodes_with_coords: List of dicts:
                {
                    'postcode': 'SK7 1AA',
                    'lat': 53.3456,
                    'lng': -2.1234
                }

        Returns:
            Sorted list of unique street names
        """
        all_streets = set()

        for pc_data in postcodes_with_coords:
            lat = pc_data.get('lat')
            lng = pc_data.get('lng')
            postcode = pc_data.get('postcode')

            if lat is None or lng is None:
                print(f"  ⚠ {postcode}: missing lat/lng, skipping")
                continue

            if self.use_api:
                streets = self._get_streets_via_api(lat, lng, postcode)
            else:
                streets = self._get_streets_via_csv(lat, lng, postcode)

            all_streets.update(streets)

        return sorted(list(all_streets))

    def _get_streets_via_csv(self, lat, lng, postcode):
        """Find streets within ~500m of postcode centroid using CSV spatial index."""
        if not self.csv_data is not None:
            return []

        # Convert radius from m to degrees (~111km per degree)
        radius_degrees = 0.5 / 111.0

        # Query KDTree
        try:
            indices = self.tree.query_ball_point([lat, lng], radius_degrees)
        except Exception as e:
            print(f"  ⚠ {postcode}: spatial query failed: {e}")
            return []

        if not indices:
            return []

        nearby = self.indexed_streets.iloc[indices]
        streets = nearby['name'].dropna().unique().tolist()

        # Filter out non-street values (numbers, empty strings)
        streets = [s for s in streets if s and not s.isdigit()]

        return streets

    def _get_streets_via_api(self, lat, lng, postcode):
        """
        Use Nominatim (free, CORS-safe from Node script) to find street names.
        Falls back to OS Names API if available (requires API key).
        """
        # Check cache first
        cache_key = f"{lat:.4f},{lng:.4f}"
        if cache_key in self.api_cache:
            return self.api_cache[cache_key]

        streets = []

        # Method 1: Try Nominatim reverse geocode (free, CORS-safe)
        try:
            nominatim_url = f"https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json"
            headers = {'User-Agent': 'LeafletCampaignTracker/1.0'}

            response = requests.get(nominatim_url, headers=headers, timeout=5)
            response.raise_for_status()

            data = response.json()
            if 'address' in data and 'road' in data['address']:
                streets.append(data['address']['road'])
                print(f"  ✓ {postcode}: found via Nominatim")

        except requests.RequestException as e:
            print(f"  ⚠ {postcode}: Nominatim error: {e}")

        # Cache result (even if empty)
        self.api_cache[cache_key] = streets

        return streets

    def enrich_routes(self, routes_with_postcodes):
        """
        Batch enrich multiple routes with street names.

        Args:
            routes_with_postcodes: List of dicts:
                {
                    'route_id': uuid,
                    'route_name': str,
                    'postcodes': [
                        {'postcode': 'SK7 1AA', 'lat': 53.3456, 'lng': -2.1234},
                        ...
                    ]
                }

        Returns:
            List of dicts with added 'streets' key
        """
        results = []

        for route in routes_with_postcodes:
            streets = self.get_streets_for_postcodes(route['postcodes'])

            result = route.copy()
            result['streets'] = streets

            results.append(result)

            print(
                f"  ✓ {route['route_name']}: {len(streets)} streets, "
                f"{len(route['postcodes'])} postcodes"
            )

        return results


def load_supabase_config():
    """Load Supabase credentials from config.js"""
    try:
        with open('config.js', 'r') as f:
            content = f.read()

        # Extract from JavaScript object format
        import re

        url_match = re.search(r'SUPABASE_URL\s*:\s*["\']([^"\']+)["\']', content)
        key_match = re.search(r'SUPABASE_KEY\s*:\s*["\']([^"\']+)["\']', content)

        if url_match and key_match:
            return url_match.group(1), key_match.group(1)
    except Exception as e:
        print(f"⚠ Could not load config.js: {e}")

    return None, None


def fetch_route_postcodes_from_db(supabase_url, supabase_key, campaign_id, route_id=None):
    """
    Fetch route postcodes from Supabase.

    Args:
        supabase_url: Supabase project URL
        supabase_key: Supabase anon key
        campaign_id: Campaign UUID (or "all")
        route_id: Specific route UUID to enrich (optional)

    Returns:
        List of dicts with route_id, route_name, postcodes
    """
    from supabase import create_client

    supabase = create_client(supabase_url, supabase_key)

    # Get target_areas for campaign
    if campaign_id == "all":
        routes_response = supabase.table('target_areas').select('id, area_name, campaign_id').execute()
    elif route_id:
        routes_response = supabase.table('target_areas').select('id, area_name, campaign_id').eq('id', route_id).execute()
    else:
        routes_response = supabase.table('target_areas').select('id, area_name, campaign_id').eq('campaign_id', campaign_id).execute()

    routes = routes_response.data

    results = []
    for route in routes:
        # Fetch postcodes for this route
        pcs_response = supabase.table('route_postcodes').select(
            'postcode, lat, lng'
        ).eq('target_area_id', route['id']).execute()

        postcodes = [
            {
                'postcode': pc['postcode'],
                'lat': pc['lat'],
                'lng': pc['lng']
            }
            for pc in pcs_response.data
        ]

        if postcodes:
            results.append({
                'route_id': route['id'],
                'route_name': route['area_name'],
                'postcodes': postcodes
            })

    return results


def update_routes_in_db(supabase_url, supabase_key, enriched_routes):
    """
    Update target_areas.streets for enriched routes.

    Args:
        supabase_url: Supabase project URL
        supabase_key: Supabase anon key
        enriched_routes: List of dicts with route_id, streets
    """
    from supabase import create_client

    supabase = create_client(supabase_url, supabase_key)

    for route in enriched_routes:
        try:
            supabase.table('target_areas').update({
                'streets': route['streets']
            }).eq('id', route['route_id']).execute()

            print(f"  ✓ Updated DB: {route['route_name']}")

        except Exception as e:
            print(f"  ✗ DB update failed for {route['route_name']}: {e}")


def main():
    """CLI entry point for enriching routes."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Enrich leaflet campaign routes with street names (OS Open Names)"
    )
    parser.add_argument(
        '--campaign',
        required=True,
        help='Campaign ID (uuid) or "all" to enrich all campaigns'
    )
    parser.add_argument(
        '--route',
        help='Specific route ID to enrich (optional; if omitted, enriches all routes in campaign)'
    )
    parser.add_argument(
        '--csv',
        help='Path to OS Open Names CSV (optional; uses API if not provided)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Print proposed changes without updating DB'
    )

    args = parser.parse_args()

    # Load Supabase config
    supabase_url, supabase_key = load_supabase_config()
    if not supabase_url or not supabase_key:
        print("[ERROR] Failed to load Supabase credentials from config.js")
        sys.exit(1)

    print(f"Enriching streets using OS Open Names...")
    if args.csv:
        print(f"  CSV mode: {args.csv}")
    else:
        print(f"  API mode (Nominatim)")

    # Initialize lookup engine
    lookup = OSNamesStreetLookup(csv_path=args.csv, use_api=not args.csv)

    # Fetch routes from DB
    print(f"\nFetching routes from {args.campaign}...")
    routes = fetch_route_postcodes_from_db(
        supabase_url, supabase_key, args.campaign, args.route
    )

    if not routes:
        print("✗ No routes found")
        sys.exit(1)

    print(f"Found {len(routes)} route(s)")

    # Enrich with street names
    print(f"\nEnriching streets...")
    enriched = lookup.enrich_routes(routes)

    # Show results
    print(f"\nResults:")
    for route in enriched:
        print(f"  {route['route_name']}: {len(route['streets'])} streets")
        if route['streets']:
            print(f"    → {', '.join(route['streets'][:5])}{'...' if len(route['streets']) > 5 else ''}")

    # Update DB
    if args.dry_run:
        print(f"\n[DRY RUN] Would update {len(enriched)} routes")
    else:
        print(f"\nUpdating DB...")
        update_routes_in_db(supabase_url, supabase_key, enriched)
        print(f"✓ Complete!")


if __name__ == '__main__':
    main()
