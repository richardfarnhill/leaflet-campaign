# Leaflet Campaign Tracker

**Commercial Delivery Management Software**  
*All rights reserved. Not for public distribution or open source use.*

---

## Overview

A card-based leaflet delivery tracking system for commercial teams. Enables teams to reserve geographic delivery areas, track deliveries, manage enquiries, and visualize campaign analytics with heatmaps.

## Features

- **Area Reservation** - Teams claim geographic chunks (800-1200 doors) with date selection
- **Real-time Availability** - Live status of available/reserved/completed areas
- **Campaign Management** - Multiple campaigns with aggregated analytics
- **Analytics Dashboard** - Charts for deliveries, enquiries, revenue over time
- **Heat Maps** - Visualize completed areas AND enquiry locations
- **Team Leaderboards** - Gamify delivery completion
- **Enquiry Tracking** - Record client details, postcode, instructions, values

## Technology Stack

- **Frontend:** Vanilla JavaScript (index.html, styles.css, app.js)
- **Backend:** Supabase (PostgreSQL + PostGIS)
- **Maps:** Leaflet.js
- **Charts:** Chart.js
- **APIs:** OS Names API, postcodes.io, Census 2021 (free)

## Setup

### 1. Clone & Install

```bash
git clone https://github.com/richardfarnhill/leaflet-campaign.git
cd leaflet-campaign
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your Supabase credentials
```

### 3. Database Setup

Run the schema in Supabase:
```bash
# Import supabase_schema.sql via Supabase SQL Editor
# Or use Supabase CLI:
supabase db push
```

### 4. Deploy

Deploy to any static hosting (Netlify, Vercel, GitHub Pages):
```bash
# Update index.html to load from .env
# (env loading implementation required)
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |
| `APP_PASSWORD` | Application password |

## Project Structure

```
leaflet-campaign/
├── index.html          # Main application
├── styles.css          # Styles (to be created)
├── app.js              # JavaScript (to be created)
├── supabase_schema.sql # Database schema
├── .env.example        # Environment template
├── .gitignore         # Git ignore rules
└── .planning/          # GSD planning docs
    ├── PROJECT.md
    ├── REQUIREMENTS.md
    ├── ROADMAP.md
    └── research/
```

## Roadmap

See `.planning/ROADMAP.md` for development phases.

### Phases

1. **Database Foundation** - ✅ Complete
2. **Territory & Reservation** - ✅ Complete
3. **Delivery Recording** - ✅ Complete
4. **Analytics & Heatmaps** - ✅ Complete
5. **Campaign Management** - ✅ Complete
6. **Enquiry & Team** - 🔄 In Progress (Route creation)
7. **Core Enhancements** - ⏳ Pending (Route cards, completion, security)
8. **Auto-assignment & API** - ⏳ Pending (Enquiry auto-assign, demographics)
9. **UI/UX** - ⏳ Pending (Dark mode)
10. **Backlog** - CSV/Sheets, Gmail, ClickUp, Planning

## Security

- **IMPORTANT:** Never commit `.env` or sensitive credentials
- Use Supabase Row Level Security (RLS) policies
- Rotate keys periodically
- Use environment variables for all secrets

## License

**PROPRIETARY - All rights reserved**

This software is commercial and confidential. Do not distribute, modify, or use without explicit permission from the owner.

---

## Support

For internal team use only. Contact the project owner for access.
