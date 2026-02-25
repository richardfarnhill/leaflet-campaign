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

## Phase 2 Status: ✅ COMPLETE

**Goal:** Teams can claim geographic chunks (800-1200 doors) with date selection

**Key Decision:** No user roles — anyone can reserve, complete, or reassign any area.

| Task | Status |
|------|--------|
| Area cards grid UI | ✅ Complete |
| Reserve modal | ✅ Complete |
| Complete modal | ✅ Complete |
| Reassign modal | ✅ Complete |
| Unassign button + modal | ✅ Complete |
| Hide completed cards | ✅ Complete |
| SB_URL scope bug | ✅ Fixed |
| Stray </script> tag | ✅ Fixed |
| DB data cleanup | ✅ Done (5 areas, all available) |
| complete_delivery soft-success bug | ✅ Fixed |

---

## Phase 3 Status: 🔄 IN PROGRESS

**Goal:** Delivery Recording — teams record completions with accurate leaflet counts

**⚠️ ACTION REQUIRED — Run this SQL in Supabase Dashboard → SQL Editor:**

```sql
CREATE OR REPLACE FUNCTION unassign_area(p_target_area_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  v_reservation_id UUID;
BEGIN
  SELECT id INTO v_reservation_id
  FROM reservations
  WHERE target_area_id = p_target_area_id AND status = 'active'
  LIMIT 1;

  IF v_reservation_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'No active reservation found');
  END IF;

  UPDATE reservations SET status = 'cancelled' WHERE id = v_reservation_id;
  UPDATE target_areas SET status = 'available' WHERE id = p_target_area_id;

  RETURN json_build_object('success', true);
END;
$$;
```

| Task | Status |
|------|--------|
| unassign_area RPC (SQL above) | ⏳ Needs manual Supabase run |
| End-to-end test (reserve → complete → unassign) | ⏳ Pending |
| Summary stats from area deliveries | ⏳ Not yet wired |

**Next Action:** Run SQL above in Supabase, then test live at localhost:3000

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
