# Requirements: Leaflet Campaign Tracker

**Project:** Card-Based Reservation System  
**Version:** 1.0 (v1)  
**Date:** 2026-02-25

---

## v1 Requirements

### TER-01: Territory & Reservation

| ID | Requirement | Description |
|----|-------------|-------------|
| TER-01 | Area Reservation System | Teams can claim geographic chunks (800-1200 doors) with a date selection |
| TER-02 | Real-time Availability | Display which areas are available/reserved/completed in real-time |
| TER-03 | Manual Override | Coordinator can reassign areas manually |

### DEM-02: Demographics

| ID | Requirement | Description |
|----|-------------|-------------|
| DEM-01 | Custom Demographic Rules | Combine multiple filters (tenure %, household type, etc.) for area selection |

### TEA-03: Team Coordination

| ID | Requirement | Description |
|----|-------------|-------------|
| TEA-01 | Progress Broadcasting | See team progress in real-time across all areas |
| TEA-02 | Leaderboards | Gamify completion - show rankings by doors delivered and revenue from instructed sales (attributed via route → team member, enabled by RTE-04 auto-matching) |

### GEO-01: Route Geocoding

| ID | Requirement | Description |
|----|-------------|-------------|
| GEO-01 | Accurate Route Geocoding | Each route must have a unique, accurate postcode representing its primary delivery street (not a parking reference). Postcode is geocoded via postcodes.io to produce correct lat/lng. OS Names API used to identify a representative street postcode where needed. No two routes in the same campaign may share the same postcode. |

### ANL-04: Analytics

| ID | Requirement | Description |
|----|-------------|-------------|
| ANL-01 | Heat Maps (Deliveries) | Visualize completed areas on a map |
| ANL-02 | Heat Maps (Enquiries) | Visualize enquiry locations on the same map |
| ANL-03 | Completion Rate by Area | Track and display completion rates per area |
| ANL-04 | Analytics Dashboard | Charts for deliveries, enquiries, revenue over time |

### CMP-05: Multi-Campaign

| ID | Requirement | Description |
|----|-------------|-------------|
| CMP-01 | Campaign Switching | Switch between different campaigns |
| CMP-02 | Aggregated Data View | View combined data across all campaigns |
| CMP-03 | Campaign Data Isolation | Chinese wall between campaigns - data from one campaign must NOT appear in another campaign's analytics, reports, or views unless "All Campaigns" is explicitly selected. Each campaign's dashboard, leaderboard, enquiries, deliveries, and stats show only that campaign's data. |

### CFG-06: Campaign Config

| ID | Requirement | Description |
|----|-------------|-------------|
| CFG-01 | Campaign Config UI | Frontend interface to update total leaflets, team members |
| CFG-02 | Response Rate Config | Edit response rate scenarios per campaign (conservative/target/optimistic %). Hardcoded baselines (0.25%/0.5%/1.0%) are acceptable fallback when no real data exists. Finance logic already uses actual enquiry/case data when available. |
| CFG-04 | Configurable Default Case Value | DEFAULT_CV (£294.42) hardcoded in app. Should be stored per campaign (e.g. campaigns.default_case_value) so different campaigns can have different average case values. Finance projections already use real avg when actual data exists — this improves the fallback. |
| CFG-03 | DB-driven Summary Bar | Summary bar (Delivered, Remaining, Sessions Done, Est. Completion, Progress %) must read from DB (campaign.target_leaflets, deliveries, target_areas) not hardcoded values. Currently 20,000 is hardcoded in app and 30,000 is in DB — must be unified. |

### ENQ-07: Enquiries

| ID | Requirement | Description |
|----|-------------|-------------|
| ENQ-01 | Robust Enquiry Recording | Capture: client name, postcode, instructed (yes/no), instruction value (£) |
| ENQ-02 | Enquiry Heatmap | Show enquiry locations on delivery coverage map |

### RTE-09: Route Management

| ID | Requirement | Description |
|----|-------------|-------------|
| RTE-01 | Route Creation UI | Add Route button + modal (name, postcode, house count, notes). Geocodes via postcodes.io. Only visible when a specific campaign is selected. |
| RTE-02 | Route Deletion UI | Delete available routes with cascade guard (reserved/completed blocked). Confirmation required. |
| RTE-03 | route_postcodes Expansion | Each route stores all unit postcodes for its OAs (not just representative). Enables enquiry auto-matching and full heatmap coverage. |
| RTE-04 | Enquiry Auto-matching | When an enquiry's postcode is recorded, auto-assign target_area_id by looking up route_postcodes. Phase 8 T4. |
| RTE-05 | Real Campaign Migration | Migrate existing real-world campaign data (routes, deliveries, enquiries) into the new data model. Phase 8. |

### DEM-10: Demographic Enrichment

| ID | Requirement | Description |
|----|-------------|-------------|
| DEM-02 | Auto-enrich demographic_feedback | When a new row is inserted into demographic_feedback (on instructed enquiry save), automatically populate owner_occupied_pct by joining on oa21_code from route_postcodes. Implemented as a PostgreSQL AFTER INSERT trigger — no external call at enquiry time. |
| DEM-03 | NOMIS backfill for route_postcodes | For each unique oa21_code in route_postcodes, fetch Census 2021 tenure data from NOMIS NM_2072_1 (TS054) and store owner_occupied_pct. One-time job per campaign; re-run when new routes are added. Data source: NOMIS API (free, no key, CORS-enabled). |

### INT-08: Integrations

| ID | Requirement | Description |
|----|-------------|-------------|
| INT-01 | ClickUp Stub | API endpoint structure for ClickUp integration (implementation v2) |
| INT-02 | Google Sheets Export | Export campaign data to Google Sheets |
| INT-03 | Gmail Notifications | Send daily/weekly report emails via Gmail |

---

## v2 Requirements (Deferred)

| ID | Category | Requirement | Notes |
|----|----------|-------------|-------|
| V2-TER-01 | Territory | Reservation Expiry | Auto-release unclaimed reservations after X days |
| V2-DEM-01 | Demographics | Census 2021 Filtering | Filter by tenure % (owner-occupied/social housing) |
| V2-TEA-01 | Team | Team Chat/Updates | In-app messaging |
| V2-TEA-02 | Team | Completion Notifications | Alert when areas complete |
| V2-ANL-01 | Analytics | Demographic Success Tracking | Correlate demographics with response rates |
| V2-INT-01 | Integrations | ClickUp Full | Full ClickUp API integration |
| V2-PLN-01 | Planning | Planning Screen | Define criteria → generate areas → create campaign |
| V2-PLN-02 | Planning | libpostal + demography | Use for intelligent chunking/area selection |

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| GPS Tracking | Privacy concerns, battery drain, overkill for walking delivery |
| Customer-facing Portal | No recipients expecting this |
| Complex Routing | Overengineering for pedestrian delivery |
| Mobile App | Web-only for v1 |
| Payment Processing | Not needed |
| Real-time Push Notifications | Annoying, use pull/daily summaries |

---

## Traceability

| Requirement | Phase | Status | Notes |
|-------------|-------|--------|-------|
| TER-01: Area Reservation System | Phase 2 | ✅ Done | Cards, reserve modal, date selection |
| TER-02: Real-time Availability | Phase 2 | ✅ Done | Cards show status, needs verification |
| TER-03: Manual Override | Phase 2 | ✅ Done | Reassign + unassign modals |
| ANL-01: Heat Maps (Deliveries) | Phase 4 | ✅ Done | T3 heatmap layer |
| ANL-02: Heat Maps (Enquiries) | Phase 4 | ✅ Done | T3 enquiry markers |
| ANL-03: Completion Rate by Area | Phase 4 | ✅ Done | T4 dashboard, T14 cards |
| ANL-04: Analytics Dashboard | Phase 4 | ✅ Done | T6 charts |
| GEO-01: Accurate Route Geocoding | Phase 4 | ✅ Done | T12 postcodes.io |
| CMP-01: Campaign Switching | Phase 5 | ✅ Done | T1 done |
| CMP-02: Aggregated Data View | Phase 5 | ✅ Done | T5 done |
| CMP-03: Campaign Data Isolation | Phase 6 | ✅ Done | Fixed queries to filter by campaign |
| CFG-01: Campaign Config UI | Phase 5 | ✅ Done | T2+T3 done |
| CFG-02: Response Rate Config | Phase 5 | ✅ Done | T6 |
| CFG-04: Configurable Default Case Value | Phase 5 | ✅ Done | T6 |
| CFG-03: DB-driven Summary Bar | Phase 5 | ✅ Done | T4 done |
| CFG-05: Restricted Areas Config | Phase 5 | ✅ Done | T9 added |
| DEM-01: Custom Demographic Rules | Phase 5 | 📋 Planned | Deferred from v1? |
| ENQ-01: Robust Enquiry Recording | Phase 6 | ✅ Done | T2 |
| ENQ-02: Enquiry Heatmap | Phase 6 | ✅ Done | T4 |
| TEA-01: Progress Broadcasting | Phase 6 | ✅ Done | T6 |
| TEA-02: Leaderboards | Phase 6 | ✅ Done | T6+T7 |
| RTE-01: Route Creation UI | Phase 6 | ✅ Done | T8 Add Route modal |
| RTE-02: Route Deletion UI | Phase 7 | ✅ Done | T2 OC |
| RTE-03: route_postcodes Expansion | Phase 6 | ✅ Done | T8 backfill — 18 rows for Tingley |
| RTE-04: Enquiry Auto-matching | Phase 8 | ✅ Done | T4 |
| RTE-05: Real Campaign Migration | Phase 8 | ✅ Done | T7 |
| DEM-02: Auto-enrich demographic_feedback | Phase 8 | 📋 Planned | T9 — trigger + NOMIS backfill |
| DEM-03: NOMIS backfill for route_postcodes | Phase 8 | 📋 Planned | T9 — prerequisite for DEM-02 trigger |
| INT-01: ClickUp Stub | Phase 9 | 📋 Backlog | - |
| INT-02: Google Sheets Export | Phase 9 | 📋 Backlog | - |
| INT-03: Gmail Notifications | Phase 9 | 📋 Backlog | - |

---

## Verification Needed (Pre-Phase 5)

| Item | Phase | Status | Action |
|------|-------|--------|--------|
| RLS policies on tables | Phase 1 | ✅ Verified | RLS enabled on all tables, public read policies (2026-02-26) |
| PostGIS spatial queries | Phase 1 | ⚠️ Unclear | Test distance calcs |
| Real-time updates | Phase 2 | ⚠️ Unclear | Verify polling/websocket |
| Delivery flow E2E | Phase 2-3 | ⚠️ Unclear | Test complete flow |
| Map/heatmap renders | Phase 4 | 🔄 Testing | T12 coords first |

---

*Last updated: 2026-02-26*
