# Phase 9 Context

## Previous Phase
Phase 8 - T9 FAILED. The approach of loading CSV data into `postcode_oa_lookup` table via Supabase MCP didn't work. Multiple batches tried, all failed.

## What We Learned
- postcodes.io v18+ already returns `oa21_code` in every response - no need to store a lookup table
- For postcodes NOT in `route_postcodes`, we need on-demand enrichment, not pre-loading
- NOMIS API can be called directly from browser JS

## New Approach: Option B (On-Demand NOMIS)
Instead of pre-loading 18k+ postcodes into DB:
1. When enquiry saved → oa21_code captured via postcodes.io (already working)
2. Frontend checks if owner_occupied_pct is NULL
3. If NULL → call NOMIS API → get tenure % → UPDATE row
4. Result: permanent demographic profile built over time

## Key Context
- oa21_code capture: already implemented in index.html (line 1812)
- trigger exists but only works for postcodes IN route_postcodes
- new approach works for ANY postcode

## Files to Modify
- index.html (add enrichDemographicFeedback function + hook into save)
- supabase_schema.sql (optional - trigger still useful for route_postcodes matches)
- Various .planning/* files (documentation)

## Supabase MCP
- Not needed for this approach
- No bulk inserts required
