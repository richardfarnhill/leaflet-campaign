# Leaflet Campaign Tracker

**Last updated:** 2026-02-25 after initialization

---

## What This Is

A leaflet delivery tracking application for politicalcampaigns that enables teams to reserve and deliver geographic areas (cards), track delivery progress, manage enquiries and cases, and visualize campaign analytics.

## Core Value

** ONE THING THAT MUST WORK: ** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.

## Problem It Solves

- Current system is date-coupled: areas are assigned to specific dates in advance
- Need to switch to date-decoupled: teams view available area cards and reserve them
- Manual tracking of sessions needs to become automated with database persistence
- Need demographic filtering to target high-value areas (60-80% owner-occupied)
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
| OS Names API integration | Get accurate street names and counts for chunking | — Pending |
| Census 2021 demographic filtering | Target 60-80% owner-occupied areas | — Pending |
| Supabase for backend | Already in use, provides auth and database | — Pending |
| Chunking strategy: keep streets together | Never split a street across delivery chunks | — Pending |

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
- [ ] OS Names API integration for street data
- [ ] Census 2021 demographic filtering (60-80% owner-occupied)
- [ ] Chunking algorithm (800-1200 doors per chunk)
- [ ] Analytics dashboard with charts
- [ ] Coverage map visualization
- [ ] Team member management
- [ ] Response rate scenarios (0.25%, 0.5%, 0.75%)

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
