# GPS Tracking Analysis for Leaflet Campaign

## Executive Summary

**Verdict: MEDIUM-HIGH complexity to implement without Docker**

The core tracking functionality is straightforward, but the infrastructure requirements are the main challenge. There are viable non-Docker options, but they require technical setup.

---

## Options Analysis (No Docker)

### Option 1: OwnTracks + Simple Backend (Recommended)

**Complexity: LOW-MEDIUM**

OwnTracks is an open-source mobile app (iOS/Android) that sends location data via MQTT or HTTP. For a non-Docker setup, you could:

- Use OwnTracks in "HTTP mode" to POST coordinates directly to a simple endpoint
- Store coordinates in Supabase (which you already use)
- Visualize on a Leaflet map in your frontend

**Requirements:**
- OwnTracks app on deliverer's phone (free)
- Supabase table to store GPS coordinates
- Simple cloud function or serverless endpoint (optional - can POST directly to Supabase)

**Feasibility: HIGH** - This is the simplest path given your existing stack.

---

### Option 2: Browser Geolocation API (Simplest)

**Complexity: LOW**

Use the browser's built-in Geolocation API in your existing app:
- Request location permission when starting a delivery
- Track coordinates in background using JavaScript
- Store in Supabase on completion

**Pros:**
- No external app needed
- Works on any smartphone browser
- Uses your existing infrastructure

**Cons:**
- Phone screen must stay on (battery drain)
- Background tracking unreliable in modern browsers
- Less accurate than dedicated GPS app

**Feasibility: MEDIUM** - Good for simple use cases, less reliable for comprehensive tracking.

---

### Option 3: GPSPEdit / GPX-Based Workflow

**Complexity: LOW**

Manual GPX file recording:
- Use a free GPS tracking app to record GPX files
- Import GPX files after delivery to visualize coverage
- No real-time tracking, but simple to implement

**Apps to consider:**
- GPS Tracks (Android, free)
- MapMyRun / RunKeeper (can track any activity)
- OSMAnd (OpenStreetMap-based, free)

**Feasibility: HIGH** - Very simple to implement, just需要一个 "Upload GPX" feature.

---

## Recommended Approach

### Phase 1: Basic GPX Import (Do First)
1. Add "Upload GPS Track" button to delivery completion form
2. Accept GPX file upload
3. Parse and store route in Supabase
4. Display on map with Leaflet

This gives you coverage visualization without real-time tracking complexity.

### Phase 2: Optional Real-Time Tracking
If you need live tracking:
1. Use OwnTracks app in HTTP mode
2. Create Supabase function to receive coordinates
3. Store in `delivery_tracks` table
4. Real-time map updates (optional)

---

## Technical Implementation Notes

### Supabase Schema for GPS Tracking

```sql
-- Store GPS tracks as JSON
ALTER TABLE deliveries ADD COLUMN gps_track JSONB;

-- Example GPS track structure:
-- [
--   {"lat": 53.1234, "lng": -2.2345, "timestamp": "2026-02-25T10:30:00Z"},
--   {"lat": 53.1235, "lng": -2.2346, "timestamp": "2026-02-25T10:30:05Z"}
-- ]
```

### Visualization with Leaflet

```javascript
// Parse GPS track and draw polyline
const track = delivery.gps_track;
const latlngs = track.map(p => [p.lat, p.lng]);
L.polyline(latlngs, {color: 'blue'}).addTo(map);
```

### Coverage Overlap Detection

To detect overlap between deliveries:
1. Convert GPS tracks to GeoJSON LineStrings
2. Use Turf.js for geospatial analysis
3. Calculate intersection percentage between tracks

---

## Effort Estimate

| Feature | Complexity | Time to Implement |
|---------|------------|-------------------|
| GPX File Upload | Low | 1-2 hours |
| Track Visualization on Map | Low | 1-2 hours |
| Overlap Detection | Medium | 4-6 hours |
| Real-time Tracking (OwnTracks) | Medium | 6-8 hours |
| Background Location (Browser) | Medium | 4-6 hours |

---

## Recommendation

Start with **GPX file upload** - it's the lowest effort way to get coverage visualization:
1. Deliverers use any free GPS app to record their route
2. After delivery, they upload the GPX file (or you do it for them)
3. All routes display on map
4. Visual overlap detection

This avoids all the complexity of real-time tracking while still giving you the coverage visualization you want.

If you later need real-time tracking, OwnTracks + Supabase is the way to go, but it requires some serverless function setup which is more complex than the current static HTML deployment.
