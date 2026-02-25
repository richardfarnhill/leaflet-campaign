# Leaflet Campaign Tracker

**Last updated:** 2026-02-25 after initialization and user feedback

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
- Single-file HTML application (index.html - 414 lines)
- Supabase backend (https://tjebidvgvbpnxgnphcrg.supabase.co)
- Hardcoded credentials in JavaScript (security concern)
- No build system, no tests
- Existing database: session_log, finance_actuals, rescheduled_sessions

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
| Card-based reservation system | Date-decoupled workflow allows teams to pick areas flexibly | — Pending |
| Multi-campaign support | Add campaign_id to all data tables, enable switching + aggregated views | — Pending |
| Campaign config UI | Allow updating campaign specifics (leaflets, team) from frontend | — Pending |
| Enquiry recording upgrade | Capture: client name, postcode, instructed (y/n), value | — Pending |
| Heatmap (deliveries + enquiries) | Visualize both completed areas AND enquiry locations | — Pending |
| OS Names API integration | Get accurate street names and counts for chunking | — Pending |
| Census 2021 demographic filtering | Target 60-80% owner-occupied areas | — Pending |
| Supabase for backend | Already in use, provides auth and database | — Pending |
| Chunking strategy: keep streets together | Never split a street across delivery chunks | — Pending |
| No FOSS alternatives used | Existing FOSS options (Fleetbase, LOBSTA) are overkill for our needs | — Pending |

## External Tools Research

### FOSS Alternatives Evaluated

| Tool | Description | Verdict |
|------|-------------|---------|
| **Fleetbase** | Open source logistics platform | Overkill - full fleet management, too complex |
| **LOBSTA** | Location-based tasks on Redmine | Overkill - enterprise-grade issue tracking |
| **dk-routing** | DataKind routing tool | Not suitable - research project, not production-ready |

**Conclusion:** Build custom solution - our requirements are specific and simpler than these general-purpose tools.

### Composio / MCP Integration

**Status:** Not recommended for v1 (requires paid API)

Relevant toolkits available:
- **Supabase** - Could integrate DB operations
- **Google Sheets** - Export data
- **Slack/Discord** - Team notifications
- **Gmail** - Auto-email reports
- **Notion** - Documentation sync
- **GitHub** - Code management

**Decision:** Revisit in v2 after core features are working.

### HuggingFace Datasets

| Dataset | Description | Relevance |
|---------|-------------|-----------|
| **libpostal** | UK address parsing (1.74M addresses) | Could help with address normalization |
| **ONS Census** | Available via data.gov.uk, not HF | Primary source for demographics |
| **demography** package | Python lib for UK postcode demographics | Useful for demographic enrichment |

**Conclusion:** Use ONS data directly from data.gov.uk (free), consider libpostal for address parsing.

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

- [ ] Card-based area reservation system
- [ ] **Multi-campaign support** with campaign_id in all tables
- [ ] **Campaign switching** - Ability to switch between campaigns
- [ ] **Aggregated data view** - See data across all campaigns
- [ ] OS Names API integration for street data
- [ ] Census 2021 demographic filtering (60-80% owner-occupied)
- [ ] Chunking algorithm (800-1200 doors per chunk)
- [ ] Analytics dashboard with charts
- [ ] **Heatmap visualization** - Show completed areas AND enquiries on map
- [ ] Team member management
- [ ] Response rate scenarios (0.25%, 0.5%, 0.75%)
- [ ] **Campaign config UI** - Frontend ability to update total leaflets, team members
- [ ] **Robust enquiry recording** - Client name, postcode, if instructed (yes/no), instruction value (£)
- [ ] **Enquiry heatmap** - Visualize enquiries on same map as delivery coverage

### Out of Scope

- GPS tracking (future phase)
- Real-time team location tracking
- Mobile app (web-only for now)
- Payment processing

---

## Git Repository

- **Remote:** https://github.com/richardfarnhill/leaflet-campaign.git
- **Current branch:** feature/card-based-reservation-system
- **Main branch:** main

---

*Last updated: 2026-02-25 after initialization*
