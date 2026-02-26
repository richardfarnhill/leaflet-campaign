# Domain Pitfalls: Leaflet Delivery Tracking

**Project:** Card-based leaflet delivery tracking
**Researched:** February 2026
**Domain:** Political campaign field operations / Delivery management

---

## Critical Pitfalls

Mistakes that cause rewrites, data corruption, or security vulnerabilities.

### Pitfall 1: Race Conditions in Territory Reservation

**What goes wrong:** Two team members reserve the same geographic chunk (800-1200 doors) simultaneously. Both see the reservation succeed. When canvassers arrive, they encounter each other or duplicate work.

**Why it happens:** 
- Web app shows "available" state
- Second user clicks reserve between first user's click and database commit
- No database-level locking on the reservation row

**Consequences:**
- Wasted volunteer time (major problem with unpaid political campaign labor)
- Duplicate delivery attempts (voters receive multiple leaflets)
- Data integrity corruption (conflicting completion status)
- Team coordination breakdown

**Prevention:**
- Use `SELECT ... FOR UPDATE` or optimistic locking with version columns
- Add unique constraint on `(chunk_id, status)` where status = 'reserved'
- Implement database-level reservation transaction:
  ```sql
  BEGIN;
  UPDATE chunks 
  SET status = 'reserved', reserved_by = $1, reserved_at = NOW()
  WHERE id = $2 AND status = 'available'
  RETURNING *;
  COMMIT;
  ```
- Check affected rows: if 0, another user got it first

**Warning signs:**
- Users reporting "I reserved it but someone else has it"
- Multiple completion records for same addresses
- Chunk status shows 'reserved' but no reserver assigned

**Phase mapping:** Must address in **Phase 1: Foundation** - reservation system core

---

### Pitfall 2: Supabase RLS Disabled or Misconfigured

**What goes wrong:** Campaign volunteer data, voter contact information, and team assignments are exposed to anyone with the project URL and anon key.

**Why it happens:**
- Supabase tables created with RLS disabled by default
- Developers assume auth is sufficient without explicit policies
- 83% of exposed Supabase databases involve RLS misconfiguration (CVE-2025-48757)

**Consequences:**
- Voter data leak (serious legal/ethical issue for political campaigns)
- Competitor can access targeting strategy
- Volunteer personal information exposed
- Campaign strategy exposed

**Prevention:**
- Enable RLS on ALL tables from the start:
  ```sql
  ALTER TABLE chunks ENABLE ROW LEVEL SECURITY;
  ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
  ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
  ```
- Write policies for each operation (SELECT, INSERT, UPDATE, DELETE)
- Test policies with anon key before deployment
- Use service role key only for migrations, never in client code

**Warning signs:**
- Can query any user's reservations without authentication
- Other teams' data visible in responses
- No permission errors when accessing random chunks

**Phase mapping:** Must address in **Phase 1: Foundation** - database schema and security

---

### Pitfall 3: OS Names API Data Gaps for Footpaths/Lanes

**What goes wrong:** Areas with only footpaths, bridleways, or private lanes return no street names from OS Names API. Canvassers receive routes with no navigable road name.

**Why it happens:**
- OS Names API includes roads but not all path types
- Some identifiers from Names API cannot be used with Linked Identifier API
- Urban vs rural coverage varies significantly

**Consequences:**
- Canvassers cannot navigate to delivery areas
- Blank chunk data (no addresses to deliver)
- Team leads cannot plan routes

**Prevention:**
- Never assume OS Names API covers 100% of target areas
- Implement fallback: cache results, have manual entry option
- Use OS Open Names data download as backup
- Test coverage on actual campaign target areas before launch

**Warning signs:**
- Large gaps in map data for certain postcodes
- API returns empty results for rural/semirural areas
- Users reporting "no streets found" errors

**Phase mapping:** Address in **Phase 2: Geographic Features** - requires testing with real target areas

---

### Pitfall 4: Census 2021 Data Mismatches with Delivery Areas

**What goes wrong:** Demographic filtering using Census 2021 data doesn't align with geographic chunks. Wrong households targeted based on outdated or misaligned census geography.

**Why it happens:**
- Census output areas don't match postcode sectors exactly
- Data aggregation levels may not align with chunk boundaries
- Census 2021 variable codes changed from 2011

**Consequences:**
- Targeting the wrong demographic (wasted leaflets)
- Campaign resources go to low-priority voters
- Cannot accurately measure demographic reach

**Prevention:**
- Document Census geography to postcode mapping methodology
- Use Lookup tables between output areas and postcodes
- Validate that filtered results match expected demographics
- Accept approximate matching; don't over-engineer exact alignment

**Warning signs:**
- Filtered results seem disproportionate to known area demographics
- Census API returns no data for certain area codes
- Variable codes not found in 2021 dataset

**Phase mapping:** Address in **Phase 2: Geographic Features** - after basic delivery tracking works

---

## Moderate Pitfalls

Mistakes that cause delays, significant rework, or technical debt.

### Pitfall 5: PostGIS Extension Not Enabled in Supabase

**What goes wrong:** Geographic queries fail with "type 'geography' does not exist" errors. Cannot perform ST_DWithin, ST_Intersects, or spatial joins.

**Why it happens:**
- PostGIS not automatically enabled on all Supabase projects
- Different extensions available on free vs paid tiers
- Tiger extension (for geocoding) has separate setup

**Prevention:**
- Verify PostGIS is enabled:
  ```sql
  SELECT * FROM pg_extension WHERE extname = 'postgis';
  ```
- Enable if missing:
  ```sql
  CREATE EXTENSION postgis;
  CREATE EXTENSION postgis_tiger_geocoder;
  ```
- Test spatial queries in Supabase SQL editor before implementing

**Warning signs:**
- "function st_x(geography) does not exist"
- "type 'norm_addy' does not exist" (geocoding)
- Spatial queries return errors

**Phase mapping:** Address in **Phase 1: Foundation** - database setup

---

### Pitfall 6: Hardcoded API Keys and Credentials

**What goes wrong:** 
- OS Data Hub API key committed to git
- Supabase service role key exposed in client code
- Census API key visible in frontend

**Consequences:**
- API quota exhausted by unknown users
- Account suspension from rate limiting
- Security audit failures
- Credential rotation requires code deploy

**Prevention:**
- Use environment variables for all secrets:
  ```
  SUPABASE_SERVICE_ROLE_KEY=
  OS_API_KEY=
  CENSUS_API_KEY=
  ```
- Never commit `.env` files (add to `.gitignore`)
- Use Supabase Vault for sensitive config
- Implement key rotation strategy

**Warning signs:**
- Git history shows API key patterns
- Console errors about missing env vars
- Different behavior in production vs local

**Phase mapping:** Address in **Phase 1: Foundation** - before any deployment

---

### Pitfall 7: Monolithic Code Structure (Existing Problem)

**What goes wrong:** Single file with mixed concerns becomes unmaintainable. Adding reservation system requires untangling delivery tracking code.

**Consequences:**
- Fear of making changes (breaks other features)
- Impossible to test individual components
- Difficult to onboard new developers
- Feature development slows dramatically

**Prevention:**
- Separate into distinct modules:
  - `lib/supabase.ts` - database client
  - `lib/territory.ts` - chunk/reservation logic
  - `lib/geography.ts` - OS Names API integration
  - `lib/demographics.ts` - Census filtering
- Write unit tests for each module
- Establish clear boundaries between components

**Warning signs:**
- Circular imports
- Functions over 100 lines
- Changes in one area break unrelated features

**Phase mapping:** Address in **Phase 1: Foundation** - refactor existing code first

---

### Pitfall 8: No Test Coverage for Critical Paths

**What goes wrong:** Reservation race condition only discovered in production. Census filtering breaks on edge cases nobody tested.

**Consequences:**
- Production incidents that could have been caught
- Manual testing becomes bottleneck
- Fear of refactoring

**Prevention:**
- Write integration tests for:
  - Concurrent reservation attempts
  - Reservation release on timeout
  - Demographic filter accuracy
- Use Supabase local development with test data
- Automate tests in CI/CD pipeline

**Warning signs:**
- "It works on my machine" responses to bugs
- Same bugs reappearing
- Manual testing checklist exists but isn't executed

**Phase mapping:** Address in **Phase 1: Foundation** - test infrastructure before features

---

### Pitfall 9: Offline-First Field Operations Not Considered

**What goes wrong:** Canvassers in rural areas with poor connectivity cannot access the app. Data entry fails, completions are lost.

**Why it happens:**
- App assumes constant connectivity
- No local storage/queue for offline actions
- Sync conflicts when reconnecting

**Consequences:**
- Lost delivery records
- Volunteer frustration
- Incomplete campaign data

**Prevention:**
- Implement offline detection
- Queue actions locally when offline
- Sync when connection restored
- Show sync status to users
- Consider PWA with service workers

**Warning signs:**
- Users reporting "app doesn't work in [area]"
- Data missing for specific geographic regions
- Sync timestamp shows old dates

**Phase mapping:** Address in **Phase 3: Field Experience** - after core features work

---

## Minor Pitfalls

Mistakes that cause annoyance but are fixable without major rework.

### Pitfall 10: Map Performance with Large Datasets

**What goes wrong:** Rendering 800-1200 addresses on map causes browser lag. Switching between chunks is slow.

**Prevention:**
- Use clustering for zoomed-out views
- Load only visible markers (viewport culling)
- Use Canvas rendering instead of DOM markers for large datasets
- Implement chunked loading with loading states

**Phase mapping:** Address in **Phase 2: Geographic Features**

---

### Pitfall 11: Chunk Size Mismatch

**What goes wrong:** 800 doors is too many for one person to complete in a session. Or 800 is too few to make efficient routes.

**Prevention:**
- Make chunk size configurable per campaign
- Allow sub-chunking (divide large chunks)
- Allow merging (combine small adjacent chunks)
- Gather feedback from canvassers

**Phase mapping:** Address in **Phase 2: Geographic Features**

---

### Pitfall 12: Timezone Handling in Reservation Expiry

**What goes wrong:** Reservations expire at wrong times. User in GMT sees UTC expiry. Campaign day vs calendar day confusion.

**Prevention:**
- Store all timestamps in UTC
- Convert to user's timezone for display
- Clarify "24 hours" in campaign context (calendar day vs campaign day)
- Use explicit datetime with timezone in UI

**Phase mapping:** Address in **Phase 2: Geographic Features**

---

### Pitfall 13: Census API Rate Limiting

**What goes wrong:** Campaign day traffic triggers Census API rate limits. Demographic filtering stops working mid-campaign.

**Prevention:**
- Cache Census results aggressively (data doesn't change)
- Pre-fetch demographics for all chunks before campaign
- Implement fallback to cached data
- Use ONS bulk download instead of API for large queries

**Phase mapping:** Address in **Phase 2: Geographic Features**

---

## Phase-Specific Warning Summary

| Phase | Critical Pitfalls | Moderate Pitfalls |
|-------|-------------------|-------------------|
| **Phase 1: Foundation** | Race conditions (1), RLS disabled (2), Hardcoded credentials (6) | PostGIS not enabled (5), Monolithic code (7), No tests (8) |
| **Phase 2: Geographic Features** | OS Names API gaps (3), Census misalignment (4) | Map performance (10), Chunk sizing (11), Timezones (12), API rate limits (13) |
| **Phase 3: Field Experience** | — | Offline operations (9) |

---

## Sources

- Supabase RLS security issues: 83% of exposed databases involve misconfiguration (CVE-2025-48757)
- OS Names API limitations: Footpaths and paths not always available in Linked Identifier API
- Race conditions in reservation systems: Well-documented pattern requiring database-level locking
- Political canvassing issues: GPS accuracy problems in rural areas, offline field operations
- Census 2021: Variable codes changed from 2011, geography alignment requires mapping tables
