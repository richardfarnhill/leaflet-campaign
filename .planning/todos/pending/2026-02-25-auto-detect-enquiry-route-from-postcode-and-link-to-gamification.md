---
created: 2026-02-25T21:30:15.797Z
title: Auto-detect enquiry route from postcode and link to gamification
area: ui
files:
  - index.html:1418-1442
  - index.html:1450-1497
---

## Problem

When recording an enquiry, the user currently has to manually select which route it came from. This is error-prone and adds friction. Since the system already knows:

1. All routes (target_areas) with their postcode prefixes and geocoordinates
2. The enquiry postcode (entered by user)

...the system should be able to **automatically detect** which route the enquiry originated from, with the user able to override if needed.

Additionally, this links to a gamification opportunity: team members who delivered a route that later generates an enquiry/instruction should receive credit — creating a direct incentive loop for quality delivery.

## Solution

### Phase 1 — Auto-detect route from postcode (no DB changes needed)
- After user enters postcode in the enquiry modal, geocode it (postcodes.io — already in the codebase)
- Compare the geocoded lat/lng against all route centroids (target_areas already have lat/lng)
- Auto-select the nearest route in the dropdown, but keep it editable
- Show a hint: "Auto-detected from postcode — WA14 area (Route 3). Change if incorrect."

### Phase 2 — DB: add lat/lng to enquiries (Phase 6 T1 already planned)
- Run migration: `ALTER TABLE enquiries ADD COLUMN lat float, ADD COLUMN lng float;`
- Store geocoded lat/lng on save (code already written, just awaiting the columns)
- This enables enquiry heatmap on the map view

### Phase 3 — Gamification link
- When an enquiry converts to an instruction, surface which route it came from
- Show on the team member's delivery record: "Route 3 delivered by John & Jane → 2 enquiries, 1 instruction (£2,500)"
- Could add a leaderboard: "Best converting routes this campaign"
- Stretch: notify team member when their route generates an enquiry

### Implementation notes
- `targetAreas` global array is already loaded when the enquiry modal opens
- Each target_area has `postcode_prefix` — quick pre-filter before distance calc
- Distance calc: simple Haversine on client side, no extra API calls needed
