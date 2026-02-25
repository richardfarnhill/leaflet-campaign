# Phase 6 Context: Enquiry & Team

**Status:** Ready to plan
**Goal:** Robust enquiry recording with client details and team progress tracking

---

## What We're Building

1. Enquiry recording: client name, postcode, instructed (yes/no), instruction value (£)
2. Enquiry heatmap - overlay instructed cases on delivery map
3. Team progress broadcasting
4. Leaderboards

---

## Requirements

- **ENQ-01:** Robust Enquiry Recording - capture client name, postcode, instructed status, value
- **ENQ-02:** Enquiry Heatmap - show enquiry locations on delivery coverage map
- **TEA-01:** Progress Broadcasting - real-time progress of all team members
- **TEA-02:** Leaderboards - ranking teams/individuals by doors delivered

---

## Dependencies

- Phase 4 - analytics dashboard, map infrastructure
- Phase 5 - campaign configuration

---

## Technical Notes

- Single-file app (index.html)
- enquiries table: id, campaign_id, client_name, postcode, location (PostGIS), instructed (boolean), instruction_value, created_at
- deliveries table for team progress/leaderboards
