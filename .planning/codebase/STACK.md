# Technology Stack

**Analysis Date:** 2026-02-25

## Languages

**Primary:**
- HTML5 - Single-page application structure
- CSS3 - Embedded styling in `<style>` block
- JavaScript (ES6+) - Vanilla JavaScript, no framework

**Secondary:**
- SQL - Database schema (Supabase/PostgreSQL)

## Runtime

**Environment:**
- Browser-based (client-side only)
- No server-side runtime required
- Static file deployment

**Package Manager:**
- None (plain static HTML, no npm/node dependencies in current state)

## External Services

**Backend Database:**
- Supabase (PostgreSQL as a Service)
- URL: `https://tjebidvgvbpnxgnphcrg.supabase.co`
- Access: REST API with JWT authentication

**Maps/Visualization:**
- Leaflet.js - Referenced in implementation plan (planned)
- OS Names API - For street data (planned integration)
- postcodes.io - For geocoding (planned integration)
- Census 2021 data - For demographic filtering (planned)

## Key Dependencies

**Current (Embedded/CDN):**
- None - All code is self-contained

**Planned:**
- Leaflet.js - Map visualization
- Chart.js - Analytics charts
- Turf.js - GPS overlap detection

## Configuration

**Environment:**
- Supabase credentials hardcoded in JavaScript:
  - `SB_URL`: `https://tjebidvgvbpnxgnphcrg.supabase.co`
  - `SB_KEY`: JWT key embedded in source

**Build:**
- No build system
- Plain HTML file deployment

## Platform Requirements

**Development:**
- Any modern browser
- Supabase account (for backend)

**Production:**
- Static file hosting (any web server)
- Supabase backend

---

*Stack analysis: 2026-02-25*
