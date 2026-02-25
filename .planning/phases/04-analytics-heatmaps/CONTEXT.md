# Phase 4 Context: Analytics & Heatmaps

**Status:** Ready to plan
**Goal:** Users can visualize delivery coverage and enquiry locations on interactive maps

---

## What We're Building

Phase 4 adds visualization capabilities to the existing card-based reservation system:
1. Interactive Leaflet map showing completed areas with heatmap overlay
2. Enquiry locations displayed on the same map
3. Completion rate stats on area cards and overall
4. Analytics dashboard with charts

---

## Requirements

- **ANL-01:** Heat Maps (Deliveries) — color-coded intensity showing delivery density
- **ANL-02:** Heat Maps (Enquiries) — enquiry locations overlaid on delivery coverage
- **ANL-03:** Completion Rate by Area — percentage display on cards and overall
- **ANL-04:** Analytics Dashboard — charts for deliveries, enquiries, revenue over time

---

## Dependencies

- Phase 3 (Delivery Recording) — requires delivery data in the deliveries table

---

## Technical Notes

- Single-file app (index.html), no build step
- Leaflet.js already loaded for the existing map
- deliveries table has: target_area_id, leaflets_delivered, delivery_date
- enquiries table has: postcode, location (lat/lng)
- target_areas table has: area_name, postcode, lat, lng (for map markers)
- Consider using Leaflet.heat or similar for heatmap layer
- Chart.js could be used for analytics dashboard (check if already loaded)

---

## Out of Scope

- Real-time tracking → future phase
- Export to PDF → future phase
- Complex date range filters → Phase 5 or 6

---

## Questions to Resolve During Planning

1. Should the map replace the card grid or sit alongside it?
2. How should heatmap intensity be calculated (door count, leaflet count)?
3. What chart types for the analytics dashboard?
4. Should completion rate be shown on cards or only in dashboard?
