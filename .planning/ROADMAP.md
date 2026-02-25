# Roadmap: Leaflet Campaign Tracker

**Project:** Card-Based Reservation System  
**Version:** 1.0  
**Date:** 2026-02-25  
**Depth:** Standard (6 phases)

---

## Overview

This roadmap delivers a complete card-based reservation system for leaflet delivery teams. The system enables teams to reserve geographic areas (800-1200 doors), record deliveries, track enquiries/cases, and visualize campaign analytics with heatmaps. Development flows from database foundation through core reservation mechanics to analytics and integrations.

---

## Phase Structure

| Phase | Goal | Dependencies | Requirements |
|-------|------|--------------|--------------|
| 1 - Database Foundation | Supabase schema with RLS and PostGIS operational | None | TER-01, TER-02, TER-03 |
| 2 - Territory & Reservation | Teams can claim geographic chunks with date selection | Phase 1 | TER-01, TER-02, TER-03 |
| 3 - Delivery Recording | Teams can record delivery completions with leaflet counts | Phase 2 | TER-01 (completion) |
| 4 - Analytics & Heatmaps | Users can visualize delivery coverage and enquiry locations | Phase 3 | ANL-01, ANL-02, ANL-03, ANL-04 |
| 5 - Campaign Management | Users can switch between campaigns and configure settings | Phase 1 | CMP-01, CMP-02, CFG-01, CFG-02, DEM-01 |
| 6 - Enquiry & Team | Robust enquiry recording with heatmap and team progress | Phase 4 | ENQ-01, ENQ-02, TEA-01, TEA-02 |
| 7 - Integrations | External tool connections (ClickUp, Sheets, Gmail) | Phase 4 | INT-01, INT-02, INT-03 |

---

## Phase Details

### Phase 1: Database Foundation

**Goal:** Supabase schema with RLS and PostGIS operational

**Requirements:** (Implicit foundation for all subsequent phases)
- Database tables: campaigns, team_members, target_areas, reservations, deliveries, enquiries
- Row Level Security enabled on all tables
- PostGIS extension enabled for spatial queries

**⚠️ CRITICAL: Data Migration Required**
- Existing data from session_log, finance_actuals, rescheduled_sessions MUST be preserved
- Migrate existing deliveries to new schema structure
- Migrate existing enquiries/cases to new schema
- Keep old tables as backup until migration verified

**Success Criteria (5):**
1. Developer can create new campaign via database or UI with name, start_date, end_date, target_leaflets
2. Developer can create team members with name, role, contact details
3. All database tables have RLS policies enforced - authenticated users can only see assigned campaign data
4. PostGIS extension is enabled and spatial queries work (distance calculations, bounding boxes)
5. **Existing delivery data migrated** - All yesterday's deliveries preserved in new schema

---

### Phase 2: Territory & Reservation

**Goal:** Teams can claim geographic chunks (800-1200 doors) with date selection

**Requirements:**
- TER-01: Area Reservation System
- TER-02: Real-time Availability
- TER-03: Manual Override

**Dependencies:** Phase 1 (requires database tables)

**Success Criteria (4):**
1. Team member can view available area cards showing geographic boundaries and door counts
2. Team member can reserve an available area card with a selected delivery date
3. System displays real-time availability status (available/reserved/completed) on all cards
4. Coordinator can manually reassign any reserved area to another team member

---

### Phase 3: Delivery Recording

**Goal:** Teams can record delivery completions with accurate leaflet counts

**Requirements:** (Implicit - delivery recording enables completion tracking)
- Delivery completion workflow
- Leaflet count validation
- Auto-update area status on completion

**Dependencies:** Phase 2 (requires reservation workflow)

**Success Criteria (4):**
1. Team member can mark a reserved area as completed with actual leaflet count delivered
2. System validates leaflet count is within expected range (±10% of target)
3. Area status automatically transitions to "completed" when delivery is recorded
4. Team member can add comments/notes to delivery record

---

### Phase 4: Analytics & Heatmaps

**Goal:** Users can visualize delivery coverage and enquiry locations on interactive maps

**Requirements:**
- ANL-01: Heat Maps (Deliveries)
- ANL-02: Heat Maps (Enquiries)
- ANL-03: Completion Rate by Area
- ANL-04: Analytics Dashboard

**Dependencies:** Phase 3 (requires delivery data)

**Success Criteria (4):**
1. User can view map showing completed areas with color-coded coverage intensity
2. User can view enquiry locations overlaid on delivery coverage map
3. User can see completion rate percentage displayed per area card and overall
4. User can view analytics dashboard with charts showing deliveries, enquiries, and revenue over time

---

### Phase 5: Campaign Management

**Goal:** Users can switch between campaigns and configure campaign settings

**Requirements:**
- CMP-01: Campaign Switching
- CMP-02: Aggregated Data View
- CFG-01: Campaign Config UI
- CFG-02: Response Rate Config
- DEM-01: Custom Demographic Rules

**Dependencies:** Phase 1 (requires campaign table structure)

**Success Criteria (4):**
1. User can switch between different campaigns via dropdown/selector
2. User can view aggregated data across all campaigns (total deliveries, enquiries, revenue)
3. User can update campaign settings: total leaflets, team members assigned, campaign dates
4. User can configure response rate scenarios (0.25%, 0.5%, 0.75%) for revenue projections
5. User can filter/prioritize areas by demographic criteria (tenure %, household type)

---

### Phase 6: Enquiry & Team

**Goal:** Robust enquiry recording with client details and team progress tracking

**Requirements:**
- ENQ-01: Robust Enquiry Recording
- ENQ-02: Enquiry Heatmap
- TEA-01: Progress Broadcasting
- TEA-02: Leaderboards

**Dependencies:** Phase 4 (requires analytics infrastructure and delivery data)

**Success Criteria (4):**
1. User can record enquiry with: client name, postcode, instructed (yes/no), instruction value (£)
2. User can view all enquiries listed with filtering by campaign, date range, instructed status
3. User can see real-time progress of all team members across all reserved areas
4. User can view leaderboard ranking teams/individuals by doors delivered

---

### Phase 7: Integrations

**Goal:** External tool connections for data export and notifications

**Requirements:**
- INT-01: ClickUp Stub
- INT-02: Google Sheets Export
- INT-03: Gmail Notifications

**Dependencies:** Phase 4 (requires delivery data)

**Success Criteria (3):**
1. Developer can access API endpoint structure for ClickUp integration (stub implementation)
2. User can export campaign data to Google Sheets with one click
3. User can configure and receive daily/weekly report emails via Gmail

---

## Progress

| Phase | Status | Requirements |
|-------|--------|--------------|
| 1 - Database Foundation | Not started | Implicit |
| 2 - Territory & Reservation | Not started | 3 |
| 3 - Delivery Recording | Not started | Implicit |
| 4 - Analytics & Heatmaps | Not started | 4 |
| 5 - Campaign Management | Not started | 5 |
| 6 - Enquiry & Team | Not started | 4 |
| 7 - Integrations | Not started | 3 |

**Total: 7 phases, 19 v1 requirements mapped ✓**

---

*Last updated: 2026-02-25*
