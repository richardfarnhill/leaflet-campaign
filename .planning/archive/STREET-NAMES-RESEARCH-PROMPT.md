# Research Prompt: Street Name Extraction for UK Postcode Routes

## Your Task

You are helping build a UK leaflet campaign tracker. Each delivery route covers a set of
unit postcodes (e.g. SK7 1AA, SK7 1AB…). The app displays the street names covered by
each route on a route card so delivery teams know which streets they're working.

We need to populate `target_areas.streets TEXT[]` in PostgreSQL — a deduplicated,
alphabetically sorted list of street names for every postcode in a route.

**The current implementation is broken.** Documentation incorrectly states that
`postcodes.io` returns a `thoroughfare` field per postcode. It does not. We have ~17
new routes with empty `streets` arrays and no working method to fill them.

Your job is to research the best available solution and produce a concrete,
implementable recommendation.

---

## Context

### What we already have per route

For each route we have:
- A list of unit postcodes (e.g. `["SK7 1AA", "SK7 1AB", "SK7 1AD", ...]`) — typically
  15–50 postcodes per route, stored in `route_postcodes` table
- OA21 codes per postcode (Census 2021 Output Area codes, e.g. `E00093872`)
- lat/lng per postcode (from postcodes.io)

### What we need

For each route, a list like:
```
["Bramhall Lane", "Bridge Lane", "Carrfield Avenue", "Davenport Road", ...]
```

Stored in `target_areas.streets TEXT[]`. Shown to delivery teams on route cards.
Accuracy matters — teams use this to know which streets they're covering.

### Constraints

- **Free APIs only** — no paid API keys. Budget is zero.
- **No build system** — single `index.html` app, but Python scripts are fine for
  backend enrichment tasks (we already use Python for NOMIS/postcodes.io calls).
- **CORS** — browser-callable APIs are a bonus but not required. Python scripts
  running server-side/locally are the primary enrichment mechanism.
- **UK only** — all postcodes are England (Cheshire/Greater Manchester area).
- **Batch efficiency** — we have ~534 postcodes across 17 routes. API calls should
  be batchable, not one-at-a-time.

### The broken approach we're replacing

`postcodes.io /postcodes?q={sector}&limit=100` — returns unit postcodes with lat/lng
and OA21 codes, but NO street name field despite documentation claiming otherwise.
Two existing routes (Tingley, Churwell) have correct streets populated but the original
source code is lost — do not rely on these as evidence of a working approach.

### API already in use (do not duplicate)

- **postcodes.io** — unit postcodes, OA21, lat/lng. Already fetched. Do not re-call for
  street names unless you find a specific endpoint that actually returns them.
- **NOMIS NM_2072_1** — Census tenure data. Not relevant to street names.

---

## Datasets and Sources to Investigate

Research each of the following thoroughly. For each, determine:
1. Does it contain UK street names per unit postcode?
2. Is it free with no API key?
3. What is the API/download format?
4. What are the rate limits and CORS status?
5. Can it be batched (e.g. 50 postcodes in one call)?
6. How accurate/complete is coverage for suburban England?

### Priority candidates

**1. Nominatim (OpenStreetMap)**
- Reverse geocode lat/lng → address including street name
- `https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json`
- Returns `address.road` field
- Free, no key. Rate limit: 1 req/sec (or use batch Overpass API?)
- Investigate: is there a batch endpoint? Can we query by postcode directly?
- Investigate: Overpass API as alternative bulk approach

**2. OS Open Names (Ordnance Survey)**
- Official UK street name dataset
- Available as free bulk download (GeoPackage/CSV) — no API key required for the
  *download*, though the API requires a key
- Investigate: can we use the bulk download in a Python script? What format?
- `https://osdatahub.os.uk/downloads/open/OpenNames`

**3. Royal Mail PAF / AddressBase**
- Gold-standard UK address data including street names
- Investigate: is any free/open subset available? (AddressBase Core was opened up)
- `https://www.ordnancesurvey.co.uk/products/addressbase`

**4. getAddress.io / ideal-postcodes / postcodes.io premium**
- Various UK postcode APIs
- Investigate whether any free tier returns street names
- Specifically check `https://api.postcodes.io` — is there ANY endpoint (undocumented
  or otherwise) that returns thoroughfare/street data?

**5. OpenStreetMap Overpass API**
- Bulk query OSM data by bounding box or postcode area
- Could query `highway=*` ways within a bounding box derived from route postcodes
- Investigate: `https://overpass-api.de/api/interpreter`
- Example: query all named streets within a lat/lng bounding box

**6. ONS ONSPD / OS Code Point Open**
- We already use ONSPD for postcodes. Does it include street names?
- OS Code Point Open: `https://osdatahub.os.uk/downloads/open/CodePointOpen`
- Investigate whether either dataset maps postcodes → street names

**7. postcodes.io source data**
- postcodes.io is open source: `https://github.com/ideal-postcodes/postcodes.io`
- What is its underlying data source? Does the raw DB contain thoroughfare?
- Their data comes from ONS ONSPD + OS Code Point — investigate if thoroughfare
  is in the source but stripped from the API response

---

## What to Produce

### 1. Ranked recommendation

Rank the viable options by:
- Accuracy and completeness for suburban England
- Ease of implementation (Python script)
- Batch efficiency (534 postcodes, don't want 534 sequential API calls if avoidable)
- Free with no key

### 2. Proof-of-concept code

For your top recommendation, write a working Python function:

```python
def get_street_names_for_postcodes(postcodes: list[str]) -> list[str]:
    """
    Given a list of unit postcodes (e.g. ["SK7 1AA", "SK7 1AB"]),
    return deduplicated, sorted street names covering those postcodes.
    Uses [YOUR CHOSEN SOURCE].
    """
```

The function should:
- Accept a list of postcodes (we already have lat/lng for each if needed)
- Return `sorted(set(street_names))` — deduped, alphabetical
- Handle rate limits gracefully (sleep/batch)
- Handle nulls/misses (some postcodes may not return a street name — skip them)

### 3. Integration note

Explain how this slots into our existing enrichment flow:
- We have `route_postcodes` rows with `postcode`, `lat`, `lng`, `oa21_code` per route
- After calling your function, we `UPDATE target_areas SET streets = ? WHERE id = ?`
- Should work as a Python script run once per route (or bulk across all routes)

### 4. Gotchas and edge cases

Note any known issues:
- Postcodes that are PO Boxes or large users (no residential street)
- Rate limiting traps
- Streets that span multiple postcodes (deduplication handles this)
- Rural postcodes with no named road
- Whether the source lags new housing developments

---

## Success Criteria

A delivery team member looking at a route card for "Bramhall A" should see a list of
actual street names they will be walking. The list should be complete enough to be
useful (e.g. 5–20 streets) and accurate enough to trust. It does not need to be
exhaustive — missing one minor cul-de-sac is acceptable.

---

## Notes on our tech stack

- Python 3.x available, `requests` library available
- Supabase (PostgreSQL) as DB — update via REST API or MCP tool
- Git Bash on Windows (not WSL) — `/tmp` doesn't work, use `c:/Users/richa/` for temp files
- SSL: use `requests.get(url, verify=False)` if SSL cert issues arise on NOMIS-style APIs
- Already have per-route postcode lists + lat/lng — you don't need to re-fetch those
