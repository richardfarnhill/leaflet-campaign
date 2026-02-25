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
| TEA-02 | Leaderboards | Gamify completion - show rankings by doors delivered |

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

### CFG-06: Campaign Config

| ID | Requirement | Description |
|----|-------------|-------------|
| CFG-01 | Campaign Config UI | Frontend interface to update total leaflets, team members |
| CFG-02 | Response Rate Config | Edit response rate scenarios (0.25%, 0.5%, 0.75%) |
| CFG-03 | DB-driven Summary Bar | Summary bar (Delivered, Remaining, Sessions Done, Est. Completion, Progress %) must read from DB (campaign.target_leaflets, deliveries, target_areas) not hardcoded values. Currently 20,000 is hardcoded in app and 30,000 is in DB — must be unified. |

### ENQ-07: Enquiries

| ID | Requirement | Description |
|----|-------------|-------------|
| ENQ-01 | Robust Enquiry Recording | Capture: client name, postcode, instructed (yes/no), instruction value (£) |
| ENQ-02 | Enquiry Heatmap | Show enquiry locations on delivery coverage map |

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
| ANL-01: Heat Maps (Deliveries) | Phase 4 | 🔄 In Progress | T3 heatmap layer done |
| ANL-02: Heat Maps (Enquiries) | Phase 4 | 🔄 In Progress | T3 enquiry markers done |
| ANL-03: Completion Rate by Area | Phase 4 | 🔄 In Progress | T4 dashboard, T14 cards |
| ANL-04: Analytics Dashboard | Phase 4 | 🔄 In Progress | T6 charts done |
| GEO-01: Accurate Route Geocoding | Phase 4 | 🔄 In Progress | T12 fixing coords via postcodes.io |
| CMP-01: Campaign Switching | Phase 5 | 📋 Planned | - |
| CMP-02: Aggregated Data View | Phase 5 | 📋 Planned | - |
| CFG-01: Campaign Config UI | Phase 5 | 📋 Planned | - |
| CFG-02: Response Rate Config | Phase 5 | 📋 Planned | - |
| CFG-03: DB-driven Summary Bar | Phase 5 | 📋 Planned | Summary bar uses campaign.target_leaflets, not 20k hardcode |
| DEM-01: Custom Demographic Rules | Phase 5 | 📋 Planned | Deferred from v1? |
| ENQ-01: Robust Enquiry Recording | Phase 6 | 📋 Planned | - |
| ENQ-02: Enquiry Heatmap | Phase 6 | 📋 Planned | - |
| TEA-01: Progress Broadcasting | Phase 6 | 📋 Planned | - |
| TEA-02: Leaderboards | Phase 6 | 📋 Planned | - |
| INT-01: ClickUp Stub | Phase 7 | 📋 Planned | - |
| INT-02: Google Sheets Export | Phase 7 | 📋 Planned | - |
| INT-03: Gmail Notifications | Phase 7 | 📋 Planned | - |

---

## Verification Needed (Pre-Phase 5)

| Item | Phase | Status | Action |
|------|-------|--------|--------|
| RLS policies on tables | Phase 1 | ⚠️ Unclear | Verify in Supabase |
| PostGIS spatial queries | Phase 1 | ⚠️ Unclear | Test distance calcs |
| Real-time updates | Phase 2 | ⚠️ Unclear | Verify polling/websocket |
| Delivery flow E2E | Phase 2-3 | ⚠️ Unclear | Test complete flow |
| Map/heatmap renders | Phase 4 | 🔄 Testing | T12 coords first |

---

*Last updated: 2026-02-25*
