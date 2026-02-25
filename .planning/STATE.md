# State: Leaflet Campaign Tracker

**Project:** Card-Based Reservation System
**Last Updated:** 2026-02-25

---

## Project Reference

**Core Value:** Teams can reserve geographic delivery areas (cards), record deliveries, and the system accurately tracks coverage, enquiries, and cases per area.

**Current Focus:** Phase 2: Territory & Reservation

---

## Current Position

| Attribute | Value |
|-----------|-------|
| **Phase** | 2 - Territory & Reservation |
| **Plan** | 7 phases defined |
| **Status** | 🔄 Phase 2 In Progress |
| **Progress** | ████████░░░░ 14% - Phase 1 ✅, Phase 2 started |

---

## Phase 1 Status: ✅ COMPLETE

| Task | Status |
|------|--------|
| Enable PostGIS | ✅ Complete |
| Create new tables | ✅ Complete |
| Insert seed data | ✅ Complete |
| Create indexes | ✅ Complete |
| Migrate session_log data | ✅ Complete |

**Supabase verified:**
- ✅ campaigns table (1 campaign: 20k_Feb_2026)
- ✅ team_members table (5 members)
- ✅ target_areas table (5 areas, all available)
- ✅ reservations table
- ✅ deliveries table
- ✅ enquiries table
- ✅ cases table
- ✅ reserve_area RPC function
- ✅ complete_delivery RPC function
- ✅ reassign_area RPC function

---

## Phase 2 Status: 🔄 IN PROGRESS

**Goal:** Teams can claim geographic chunks (800-1200 doors) with date selection

**Key Decision:** No user roles — anyone can reserve, complete, or reassign any area.

| Task | Status | Notes |
|------|--------|-------|
| Area cards grid UI | ✅ Complete | Renders available/reserved/completed |
| Reserve modal | ✅ Complete | Team member + date picker |
| Complete modal | ✅ Complete | Leaflet count + notes |
| Reassign modal | ✅ Complete | Any user can reassign (no role gate) |
| SB_URL scope bug | ✅ Fixed | Was scoped inside IIFE, now at script level |
| Stray </script> tag | ✅ Fixed | Was breaking all JS below Logger block |
| DB data cleanup | ✅ Done | Reset 5 areas to available, removed duplicate |
| End-to-end test | ⏳ Pending | Reserve → Complete → Reassign flow not yet verified live |

**Success Criteria (from ROADMAP):**
1. ⏳ Team member can view available area cards with door counts
2. ⏳ Team member can reserve an area with a delivery date
3. ⏳ Status updates in real-time (available → reserved → completed)
4. ⏳ Any user can reassign a reserved area

**Next Action:** Test the live flows at localhost:3000, then run `/gsd:plan-phase 3`

---

## Roadmap Summary

| Phase | Goal | Status |
|-------|------|--------|
| 1 - Database Foundation | Supabase schema with RLS and PostGIS operational | ✅ Complete |
| 2 - Territory & Reservation | Teams can claim geographic chunks with date selection | 🔄 In Progress |
| 3 - Delivery Recording | Teams can record delivery completions with leaflet counts | ⏳ Pending |
| 4 - Analytics & Heatmaps | Users can visualize delivery coverage and enquiry locations | ⏳ Pending |
| 5 - Campaign Management | Users can switch between campaigns and configure settings | ⏳ Pending |
| 6 - Enquiry & Team | Robust enquiry recording with heatmap and team progress | ⏳ Pending |
| 7 - Integrations | External tool connections (ClickUp, Sheets, Gmail) | ⏳ Pending |

**Total:** 7 phases, 19 v1 requirements mapped ✓

---

## Coverage Map

### Phase 2: Territory & Reservation
- TER-01: Area Reservation System
- TER-02: Real-time Availability
- TER-03: Manual Override (no role gate — anyone can reassign)

### Phase 3: Delivery Recording
- TER-01 (completion workflow)

### Phase 4: Analytics & Heatmaps
- ANL-01: Heat Maps (Deliveries)
- ANL-02: Heat Maps (Enquiries)
- ANL-03: Completion Rate by Area
- ANL-04: Analytics Dashboard

### Phase 5: Campaign Management
- CMP-01: Campaign Switching
- CMP-02: Aggregated Data View
- CFG-01: Campaign Config UI
- CFG-02: Response Rate Config
- DEM-01: Custom Demographic Rules

### Phase 6: Enquiry & Team
- ENQ-01: Robust Enquiry Recording
- ENQ-02: Enquiry Heatmap
- TEA-01: Progress Broadcasting
- TEA-02: Leaderboards

### Phase 7: Integrations
- INT-01: ClickUp Stub
- INT-02: Google Sheets Export
- INT-03: Gmail Notifications

---

## Key Decisions

| Decision | Rationale | Phase |
|----------|-----------|-------|
| Phases derived from requirements | Natural delivery boundaries based on dependencies | All |
| Database Foundation as Phase 1 | Required for all subsequent phases | 1 |
| No user roles | Anyone can reserve/complete/reassign — keep it simple | 2 |
| Territory before Analytics | Core reservation workflow before visualization | 2→4 |
| Campaign + Demographics combined | Both need campaign infrastructure | 5 |
| Enquiry + Team combined | Both build on analytics data | 6 |
| Integrations last | Non-critical for core workflow | 7 |

---

## Dependencies

```
Phase 1 (Database Foundation)
    ↓
Phase 2 (Territory & Reservation) → Phase 3 (Delivery Recording)
    ↓
Phase 4 (Analytics & Heatmaps) → Phase 5 (Campaign Management) [both need Phase 1]
                           ↓
                    Phase 6 (Enquiry & Team) [needs Phase 4]
                           ↓
                    Phase 7 (Integrations) [needs Phase 4 data]
```

---

## Session Continuity

**Branch:** `feature/card-based-reservation-system`
**Next Action:** Test Phase 2 live at localhost:3000, then `/gsd:plan-phase 3`

**Questions for User:**
- None outstanding

---

*Last updated: 2026-02-25*
