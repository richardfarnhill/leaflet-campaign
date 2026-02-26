# Leaflet Campaign Tracker

**Last updated:** 2026-02-26 after Phase 6 T8 completion and Phase 7 complete

---

## What This Is

A **commercial** leaflet delivery tracking application that enables teams to reserve and deliver geographic areas (cards), track delivery progress, manage enquiries and cases, and visualize campaign analytics with heatmaps.

## Core Value

** ONE THING THAT MUST WORK: ** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.

## Problem It Solves

- Current system is date-coupled: areas are assigned to specific dates in advance
- Need to switch to date-decoupled: teams view available area cards and reserve them
- Need multi-campaign support: ability to manage multiple campaigns and see aggregated data
- Need robust enquiry recording: client name, postcode, instruction status, value
- Need heatmap visualization: show completed areas AND enquiries on a map
- No analytics currently - need charts for deliveries, enquiries, revenue over time

## Target Users

- Campaign managers (Richard) tracking overall progress
- Delivery teams (Josh, Dan, Cahner, Orla) reserving and completing areas
- Geographic scope: 15 miles from WA14 (Altrincham)

## Technical Context

**Current State:**
- Single-file HTML application (index.html - ~2200 lines)
- Supabase backend (https://tjebidvgvbpnxgnphcrg.supabase.co)
- Credentials moved to config.js (Phase 7 T5)
- RLS enabled on all tables (Phase 7 T3)
- No build system, no tests
- Database: campaigns, target_areas, route_postcodes, reservations, deliveries, enquiries, team_members, restricted_areas

**Target State:**
- Multi-file structure: index.html, styles.css, app.js
- New database schema with: campaign_config, team_members, target_areas, reservations, deliveries, enquiries, cases
- OS Names API for street data
- Census 2021 demographic data for filtering
- Card-based UI with reservation system
- Analytics dashboard

## Constraints

- **Timeline:** 12-16 weeks estimated
- **Budget:** Free APIs preferred (OS Names, Census 2021, postcodes.io)
- **Team:** 5 members (Richard, Josh, Dan, Cahner, Orla)
- **Geographic:** 15 miles from WA14, excluding WA14/WA15/M33/inner areas

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Card-based reservation system | Date-decoupled workflow allows teams to pick areas flexibly | ✅ Done |
| Multi-campaign support | Add campaign_id to all data tables, enable switching + aggregated views | ✅ Done |
| Campaign config UI | Allow updating campaign specifics (leaflets, team) from frontend | ✅ Done |
| Enquiry recording upgrade | Capture: client name, postcode, instructed (y/n), value | ✅ Done |
| Heatmap (deliveries + enquiries) | Visualize both completed areas AND enquiry locations | ✅ Done |
| Team progress + leaderboards | Track leaflets delivered (split if 2 members) + revenue from enquiries | ✅ Done |
| OS Names API integration | Get accurate street names and counts for chunking | ⚠️ Requires API key — replaced by postcodes.io + NOMIS |
| Census 2021 demographic filtering | Target 60-80% owner-occupied areas | ✅ Designed — NOMIS NM_2072_1 (TS054 Tenure) |
| **Route Planning Engine** | **Resolve area → postcodes → demographic filter → exclusion check → chunked routes → DB** | **🔧 Phase 8 — see [ROUTE-PLANNING-ENGINE.md](ROUTE-PLANNING-ENGINE.md). Manual Add Route UI done (Phase 6 T8).** |
| **libpostal + demography integration** | **CRITICAL - chunking and area selection from criteria** | 🔧 Phase 8/9 — postcodes.io + NOMIS handles demographic filtering; libpostal for address parsing/normalisation |
| **Planning Screen** | Define criteria → generate areas → create campaign in DB | 🔧 Phase 6 T8 — implemented as `/leaflet-plan-routes` skill |
| **ClickUp integration stub** | Create API structure for ClickUp, full implementation v2 | — Pending |
| Supabase for backend | Already in use, provides auth and database | ✅ Done |
| Chunking strategy: keep streets together | Never split a street across delivery chunks | — Pending |
| **Composio integration** | Use free toolkits - Google Sheets, ClickUp, Gmail, etc. | — Pending |
| No FOSS alternatives used | Existing FOSS options (Fleetbase, LOBSTA) are overkill for our needs | ✅ Done |

## External Tools Research

### FOSS Alternatives Evaluated

| Tool | Description | Verdict |
|------|-------------|---------|
| **Fleetbase** | Open source logistics platform | Overkill - full fleet management, too complex |
| **LOBSTA** | Location-based tasks on Redmine | Overkill - enterprise-grade issue tracking |
| **dk-routing** | DataKind routing tool | Not suitable - research project, not production-ready |

**Conclusion:** Build custom solution - our requirements are specific and simpler than these general-purpose tools.

### Composio / MCP Integration

**Status:** REVISED - Use free toolkits!

Free toolkits to use:
- **Google Sheets** - Export campaign data
- **ClickUp** - Integration stub (create API endpoints)
- **Gmail** - Auto-email reports
- **Notion** - Documentation sync
- **Slack/Discord** - Team notifications
- And 850+ others with free tiers

**Decision:** Create stub integration in v1, full implementation v2.

### libpostal + demography (CRITICAL!)

These are **essential** for the chunking/planning workflow:

| Library | Purpose | Use Case |
|---------|---------|----------|
| **libpostal** | UK address parsing & normalization | Parse street names, validate postcodes |
| **demography** | UK postcode demographic data | Filter by owner-occupied %, social housing % |
| **ONS Census** | Official UK demographics | Source for tenure data |
| **OS Names API** | Street names & locations | Get accurate street data |

**Planning Screen workflow (v2):**
1. User enters: Total leaflets (50,000), chunk size (850), demographics (social housing ONLY), radius (20 miles), centre postcode (E4 9UT)
2. System uses libpostal + demography + ONS data to:
   - Find all streets within radius
   - Filter by demographic criteria
   - Chunk into appropriate sizes (never split streets)
3. User reviews → clicks "Create Campaign"
4. Campaign + target_areas created in Supabase

### HuggingFace Datasets

| Dataset | Description | Relevance |
|---------|-------------|-----------|
| **libpostal** | UK address parsing (1.74M addresses) | CRITICAL for chunking |
| **demography** package | Python lib for UK postcode demographics | CRITICAL for filtering |
| **ONS Census** | Available via data.gov.uk, not HF | Primary source for demographics |

**Conclusion:** Use ONS data + libpostal + demography together for intelligent area selection.

## Existing Code (Brownfield)

This is a brownfield project. Codebase analysis completed:

- **STACK.md:** HTML/CSS/JS, Supabase backend, Leaflet planned
- **ARCHITECTURE.md:** Single-page app, client-side only, in-memory state
- **CONCERNS.md:** 18 issues identified (security, architecture, testing gaps)
- **QUALITY.md:** Code quality assessment with ratings across 12 dimensions

### Validated Requirements (from existing code)

- ✓ Session tracking with staff assignments
- ✓ Delivery recording with comments
- ✓ Finance tracking (enquiries and cases)
- ✓ Summary statistics (delivered, pending, completed %)
- ✓ Sync status indicator
- ✓ Password-based authentication (insecure - hardcoded)

### Active Requirements (new)

- [x] Card-based area reservation system
- [x] **Multi-campaign support** with campaign_id in all tables
- [x] **Campaign switching** - Ability to switch between campaigns
- [x] **Aggregated data view** - See data across all campaigns
- [x] Analytics dashboard with charts
- [x] **Heatmap visualization** - Show completed areas AND enquiries on map
- [x] Team member management (route-level)
- [x] Response rate scenarios (0.25%, 0.5%, 0.75%)
- [x] **Campaign config UI** - Frontend ability to update total leaflets, team members
- [x] **Robust enquiry recording** - Client name, postcode, if instructed (yes/no), instruction value (£)
- [x] **Enquiry heatmap** - Visualize enquiries on same map as delivery coverage
- [x] **Team progress tracking** - Real-time progress of team members
- [x] **Leaderboards** - Rank by leaflets delivered (split if 2 members) AND revenue from instructed enquiries
- [x] **Route creation UI** - Add Route modal with geocoding
- [x] **Route deletion UI** - Delete with cascade guard
- [x] **route_postcodes expansion** - Full unit postcodes per route (enquiry auto-matching)
- [x] **Security** - Credentials in config.js, RLS enabled
- [ ] **Enquiry auto-matching** - Auto-assign enquiries to routes via route_postcodes lookup (Phase 8 T4)
- [ ] **Refactor real campaigns** - Migrate existing real campaign data into new model (Phase 8 T7)
- [ ] OS Names API integration for street data (deferred)
- [ ] Census 2021 demographic filtering (deferred — NOMIS NM_2072_1 approach designed)
- [ ] **libpostal + demography integration** - Critical for intelligent chunking/area selection (Phase 8/9)
- [ ] **ClickUp integration stub** - API endpoints for ClickUp (Phase 9 backlog)
- [ ] **Planning Screen** - Define criteria → generate areas → create campaign (Phase 8/9)

### Out of Scope

- GPS tracking (future phase)
- Real-time team location tracking
- Mobile app (web-only for now)
- Payment processing

---

## Current State (Phase 7 Complete)

**Last activity:** 2026-02-26
**Status:** Phases 1-7 fully complete. Phase 8 next.

### What's Been Delivered
- Card-based area reservation system
- Multi-campaign support with data isolation (Chinese wall)
- Analytics dashboard with charts
- Heat maps (deliveries + enquiries)
- Team leaderboards (leaflets + revenue)
- Robust enquiry recording with geocoding
- Route creation UI (+ Add Route modal)
- Route deletion UI with cascade
- Per-postcode exclusion radius config
- Credentials in config.js, RLS enabled
- route_postcodes table: full unit postcode expansion (enquiry auto-matching ready)
- Route card street names (click-to-expand) + map boundary polygon (Turf.js convex hull)

### Next Milestone Goals (Phase 8)
- Auto-assign enquiries to routes (via route_postcodes lookup)
- Refactor existing real campaigns into the new data model
- Prompt to add routes when house count is short
- API endpoints via Supabase

---

## Git Repository

- **Remote:** https://github.com/richardfarnhill/leaflet-campaign.git
- **Current branch:** feature/card-based-reservation-system
- **Main branch:** main

---

*Last updated: 2026-02-25 after Phase 6 progress (enquiry recording, team progress, leaderboards)*
