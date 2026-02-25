# Phase 2: Territory & Reservation - Execution Plan

## Overview

**Phase:** 2 - Territory & Reservation  
**Goal:** Teams can claim geographic chunks (800-1200 doors) with date selection  
**Requirements:** TER-01, TER-02, TER-03

---

## Dependencies

- **Requires:** Phase 1 complete (Supabase schema with campaigns, team_members, target_areas, reservations tables)
- **Phase 1 tables exist:** ✅

---

## Tasks Breakdown

### Task 1: Backend - Reservation Logic (Supabase Functions)

**Files:** Supabase SQL Editor

**Action:**
1. Create `reserve_area` function:
   - Accept: target_area_id, team_member_id, delivery_date
   - Validate: area status is 'available', team_member exists
   - Insert reservation record with status 'reserved'
   - Update target_area status to 'reserved'
   - Return reservation details

2. Create `release_area` function:
   - Accept: target_area_id
   - Validate: reservation exists and is 'reserved'
   - Update reservation status to 'released'
   - Update target_area status to 'available'
   - Return success

3. Create `reassign_area` function (for manual override):
   - Accept: target_area_id, new_team_member_id
   - Validate: reservation exists
   - Update reservation team_member_id
   - Return updated reservation

4. Create trigger `after_reservation_insert`:
   - After inserting reservation, update target_areas.status to 'reserved'

**Verify:**
- SQL functions execute without errors in Supabase SQL Editor
- Functions return expected data structures

**Done:**
- 3 Supabase functions exist: reserve_area, release_area, reassign_area
- Trigger updates target_area status automatically

---

### Task 2: Frontend - Area Card Display

**Files:** index.html (additions)

**Action:**
1. Add campaign selector (dropdown) in header area:
   - Fetch campaigns from Supabase
   - Store selected campaign_id in JS state
   - Load target_areas for selected campaign

2. Create area cards grid layout:
   - Display cards in CSS grid (3 columns desktop, 1 mobile)
   - Each card shows: area name, postcode, door count, geographic boundary info, status badge

3. Add status badges with colors:
   - Available: green (#27ae60)
   - Reserved: orange (#f39c12)
   - Completed: blue (#2e86ab)

4. Display team member name on reserved cards:
   - Show who reserved the area
   - Show delivery date

**Verify:**
- Cards render with correct data from Supabase
- Status badges show correct colors
- Reserved cards show team member and date

**Done:**
- Team member can view available area cards showing geographic boundaries and door counts
- Cards display correct status (available/reserved/completed)

---

### Task 3: Frontend - Reservation Workflow

**Files:** index.html (additions)

**Action:**
1. Add reservation modal/dialog:
   - Opens when clicking "Reserve" button on available card
   - Shows: team member dropdown, date picker
   - Buttons: Confirm, Cancel

2. Implement reservation API call:
   - On confirm, call `reserve_area` Supabase function
   - Handle success: update card status, show success message
   - Handle error: show error message

3. Add date validation:
   - Minimum: tomorrow
   - Maximum: campaign end date + 30 days

4. Add loading states:
   - Disable button during API call
   - Show spinner/text change

**Verify:**
- Clicking "Reserve" opens modal
- Can select team member and date
- Confirm creates reservation in Supabase
- Card updates to "Reserved" status

**Done:**
- Team member can reserve an available area card with a selected delivery date

---

### Task 4: Real-time Availability (Polling)

**Files:** index.html (modifications)

**Action:**
1. Implement polling for target_areas:
   - Poll every 30 seconds (like existing session loading)
   - Fetch target_areas for current campaign
   - Update card statuses in UI

2. Add visual refresh indicator:
   - Show "Updating..." during fetch
   - Show "Live" when update complete

3. Optimize polling:
   - Only poll when tab is visible (Page Visibility API)
   - Debounce rapid status changes

**Verify:**
- Changes from other users appear within 30 seconds
- No excessive API calls

**Done:**
- System displays real-time availability status on all cards

---

### Task 5: Manual Override (Coordinator Reassignment)

**Files:** index.html (additions)

**Action:**
1. Add "Reassign" button on reserved cards:
   - Only visible to coordinator (Richard)
   - Opens reassign modal

2. Create reassign modal:
   - Shows current team member (read-only)
   - Dropdown to select new team member
   - Confirm/Cancel buttons

3. Implement reassign API call:
   - Call `reassign_area` Supabase function
   - Update card with new team member
   - Log change for audit trail

4. Add coordinator detection:
   - Check team member role or name
   - Show/hide reassign controls based on role

**Verify:**
- Reassign button visible on reserved cards for coordinator
- Selecting new team member and confirming updates reservation
- Card shows new team member name

**Done:**
- Coordinator can manually reassign any reserved area to another team member

---

## Success Criteria Mapping

| Criterion | Task |
|-----------|------|
| 1. Team member can view available area cards showing geographic boundaries and door counts | Task 2 |
| 2. Team member can reserve an available area card with a selected delivery date | Task 3 |
| 3. System displays real-time availability status on all cards | Task 4 |
| 4. Coordinator can manually reassign any reserved area to another team member | Task 5 |

---

## Implementation Order

1. **Task 1** (Backend) - Must complete first, enables all other tasks
2. **Task 2** (Card Display) - Foundation UI
3. **Task 3** (Reservation) - Core functionality
4. **Task 4** (Real-time) - Enhancement
5. **Task 5** (Override) - Coordinator feature

---

## Technical Notes

- **Supabase API:** Use REST API with existing pattern from index.html (sbFetch function)
- **State Management:** Add targetAreas array to sessionState
- **Styling:** Reuse existing card styles from .session-card
- **No new files needed:** All changes in index.html (single-file app)
