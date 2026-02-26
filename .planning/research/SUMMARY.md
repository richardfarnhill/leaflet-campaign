# Research Summary: Leaflet Campaign Tracker

**Project:** Card-Based Reservation System for Political Campaign Leaflet Delivery  
**Date:** 2026-02-25  
**Synthesized:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md

---

## Executive Summary

This project adds a card-based reservation system to an existing single-page leaflet delivery tracking app. The core innovation is decoupling "what to deliver" (territory chunks) from "when to deliver" (date selection), allowing teams of 5 to claim geographic chunks of 800-1200 doors rather than being assigned sessions by date.

The recommended stack leverages existing infrastructure (Vanilla JS, Supabase) with strategic additions: Leaflet.js for mapping, Turf.js for client-side chunking, PostGIS for spatial queries, and UK-specific data sources (OS Names API, postcodes.io, Census 2021). The architecture separates concerns into Territory Management, Reservation Workflow, Delivery Recording, and Analytics layers—each building on the previous.

**Critical risks identified:** Race conditions in concurrent reservations, Supabase RLS misconfiguration exposing voter data, and OS Names API coverage gaps for footpaths/lanes. These must be addressed in Phase 1. Demographic filtering via Census 2021 is a strong differentiator but should wait until Phase 2 after core reservation mechanics are proven.

---

## Key Findings

### From STACK.md

| Technology | Version | Purpose |
|------------|---------|---------|
| Vanilla JavaScript | ES2022+ | Application logic (existing, no framework needed) |
| Leaflet.js | 1.9.4 | Map visualization (free, open-source, no API key) |
| Chart.js | 4.x | Analytics charts |
| Turf.js | 3.0.14 | Client-side geographic chunking |
| Supabase | Managed | Backend: PostgreSQL + Auth + REST API |
| PostGIS | 3.x | Spatial queries (CRITICAL: enable via Supabase Dashboard) |
| OS Names API | Free tier | UK street data (2.5M places) |
| postcodes.io | Free | Postcode validation, geocoding (30 req/sec) |
| Census 2021 | NOMIS/ONS | Demographic filtering (owner-occupied %) |

**Key rationale:** Existing vanilla JS codebase requires no framework migration. Supabase already provides PostgreSQL with PostGIS—adding mapping libraries completes the stack without new infrastructure. OS Names API and postcodes.io are free, requiring no API keys for basic tier.

### From FEATURES.md

**Table Stakes (Expected):**
- Delivery recording, session management, location verification
- Basic mapping, door count tracking
- Address data storage, progress indicators, export capability
- User authentication, team member management

**Differentiators (Valued):**
- Area reservation system (prevent duplicate delivery)
- Census 2021 demographic filtering (target owner-occupied areas)
- Real-time team progress broadcasting
- Completion rate analytics by area

**Anti-Features (Avoid):**
- Real-time GPS tracking (privacy, battery, overkill)
- Customer-facing tracking portal (no recipients expecting this)
- Complex routing algorithms (pedestrian delivery doesn't need it)
- Multi-language support (UK-only campaign)

### From ARCHITECTURE.md

**Component Boundaries:**
1. **Territory Management** — Define geographic chunks (800-1200 doors)
2. **Reservation Workflow** — Claim territories with date selection
3. **Delivery Recording** — Record completion with leaflet counts
4. **Analytics & Display** — Aggregate progress, revenue projections

**Critical insight:** Decouple territory (what) from session (when). Current system tracks sessions by date with embedded data. New system should track territories independently, allowing teams to select their own delivery dates.

**Build Order:**
1. target_areas table + status transitions
2. reservations table + card selection UI
3. deliveries table + completion recording
4. Analytics dashboard with progress calculations

### From PITFALLS.md

**Critical (Must Fix in Phase 1):**
1. **Race conditions** — Concurrent reservation attempts create duplicate claims. Use `SELECT ... FOR UPDATE` or optimistic locking.
2. **RLS disabled** — 83% of exposed Supabase databases have misconfigured RLS. Enable on ALL tables from start.
3. **OS Names API gaps** — Footpaths, bridleways, private lanes may return no data. Test coverage before launch.

**Moderate:**
4. PostGIS extension not enabled (verify in Supabase Dashboard)
5. Hardcoded API keys in client code
6. Monolithic code structure (refactor existing app.js first)
7. No test coverage for critical paths

**Minor (Address in Phase 2+):**
- Map performance with large datasets (use clustering)
- Chunk size mismatch (make configurable)
- Timezone handling in reservation expiry
- Census API rate limiting (pre-fetch and cache)

---

## Implications for Roadmap

### Recommended Phase Structure

**Phase 1: Territory & Reservation Foundation** (Weeks 1-2)
- Create `target_areas` table with status field (available/reserved/completed)
- Implement `reservations` table with team_member, delivery_date, status
- Build card selection UI showing available territories
- **Must fix:** Race conditions (database-level locking), RLS enabled on all tables
- **Must fix:** Enable PostGIS extension, refactor monolithic app.js
- Deliverable: Cards display available chunks, teams can claim with date selection

**Phase 2: Delivery Recording & Progress** (Weeks 2-3)
- Create `deliveries` table linked to reservations
- Input leaflet count with validation
- Auto-update status on completion
- Progress calculations (delivered vs total)
- **Pitfalls to avoid:** OS Names API gaps (test coverage), map performance (clustering)
- Deliverable: Teams record completions, progress percentage visible on cards

**Phase 3: Analytics & Team Features** (Weeks 3-4)
- Completion rate by area analytics
- Team progress broadcasting
- Revenue projections (reuse existing finance logic)
- Card-based UI with status indicators
- Deliverable: Dashboard showing team performance, completion trends

**Phase 4: Demographic Targeting (Optional)** (Weeks 4-5)
- Census 2021 data import (owner-occupied percentages)
- Filter chunks by demographic criteria
- Demographic success tracking (correlate with enquiry rates)
- **Pitfall:** Census geography misalignment—use lookup tables, accept approximate matching
- Deliverable: Filter areas by target demographics, measure demographic reach

**Phase 5: External Data Integration** (Ongoing)
- OS Names API for street-level data
- Postcodes.io for validation
- GPS bounds visualization on map
- **Pitfall:** API rate limits—implement caching, pre-fetch data
- Deliverable: Richer territory data, improved mapping

### Research Flags

| Phase | Needs Research | Standard Patterns |
|-------|----------------|-------------------|
| Phase 1 | RLS policy specifics | Territory management (well-documented) |
| Phase 2 | — | Delivery recording (mirrors session tracking) |
| Phase 3 | — | Analytics (standard Chart.js patterns) |
| Phase 4 | Census 2021 variable mapping | Geographic filtering (PostGIS + census join) |
| Phase 5 | OS Names API edge cases | UK geocoding (postcodes.io patterns) |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | HIGH | Technologies verified with current documentation. Supabase + PostGIS + Leaflet is well-established combination. |
| **Features** | MEDIUM | Table stakes from multiple competing products. Differentiators based on market research and inference. |
| **Architecture** | HIGH | Matches patterns from Knockbase, Ecanvasser, NGP VAN. Component boundaries and build order logically sound. |
| **Pitfalls** | HIGH | Race conditions and RLS issues well-documented. OS Names API gaps identified from UK-specific sources. |

**Overall Confidence: HIGH**

Key gaps identified:
- Census 2021 variable codes require verification against actual ONS dataset
- OS Names API coverage should be tested with real campaign postcodes
- Concurrent reservation behavior needs load testing

---

## Sources Aggregated

- **Leaflet.js:** https://leafletjs.com/ (v1.9.4, August 2025)
- **Chart.js:** https://www.chartjs.org/ (v4.x)
- **Supabase PostGIS:** https://supabase.com/docs/guides/database/extensions/postgis
- **OS Names API:** https://www.ordnancesurvey.co.uk/products/os-names-api
- **postcodes.io:** https://postcodes.io/ (MIT licensed)
- **ONS Census 2021:** https://www.nomisweb.co.uk/query/construct/census2021.asp
- **Knockbase/Ecanvasser:** Territory management patterns
- **NGP VAN:** Political campaign CRM data model
- **CVE-2025-48757:** Supabase RLS misconfiguration statistics
