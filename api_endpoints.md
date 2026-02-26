# API Endpoints Documentation

---

## Quick Start for Data Analyst

**API URL:** `https://tjebidvgvbpnxgnphcrg.supabase.co`

**API Key (anon):** Get from `config.js` → `CONFIG.SUPABASE_KEY`

---

## `get_delivery_stats` RPC

**Endpoint:** `POST /rest/v1/rpc/get_delivery_stats`

**Parameters - MUST provide all three:**

| Parameter | Example | Description |
|-----------|---------|-------------|
| `p_campaign_id` | (empty) | UUID of campaign. Empty = all campaigns. |
| `p_start_date` | `2026-02-01` | Start date (YYYY-MM-DD) |
| `p_end_date` | `2026-02-28` | End date (YYYY-MM-DD) |

---

## Example Queries

### All time
```
https://tjebidvgvbpnxgnphcrg.supabase.co/rest/v1/rpc/get_delivery_stats?p_campaign_id=&p_start_date=&p_end_date=&apikey=YOUR_KEY
```

### February 2026
```
https://tjebidvgvbpnxgnphcrg.supabase.co/rest/v1/rpc/get_delivery_stats?p_campaign_id=&p_start_date=2026-02-01&p_end_date=2026-02-28&apikey=YOUR_KEY
```

### Q1 2026 (Jan-Mar)
```
https://tjebidvgvbpnxgnphcrg.supabase.co/rest/v1/rpc/get_delivery_stats?p_campaign_id=&p_start_date=2026-01-01&p_end_date=2026-03-31&apikey=YOUR_KEY
```

### December 2025
```
https://tjebidvgvbpnxgnphcrg.supabase.co/rest/v1/rpc/get_delivery_stats?p_campaign_id=&p_start_date=2025-12-01&p_end_date=2025-12-31&apikey=YOUR_KEY
```

---

## Response Fields

| Field | Description |
|-------|-------------|
| `total_leaflets_all_time` | Total leaflets delivered ever |
| `leaflets_in_period` | Leaflets in selected date range |
| `leaflets_last_30_days` | Leaflets in last 30 days |
| `routes_completed_count` | Number of completed routes |
| `active_routes_count` | Number of reserved routes |
| `total_revenue` | Total instruction value (£) ever |
| `revenue_in_period` | Instruction value in date range |
| `revenue_per_100_leaflets` | Revenue per 100 leaflets |
| `enquiries_count` | Total enquiries ever |
| `enquiries_in_period` | Enquiries in date range |
| `cases_count` | Total instructed cases |
| `cases_in_period` | Cases in date range |
| `conversion_rate` | % of enquiries that became cases |
| `average_case_value` | Average £ per case |

---

## Table Queries (REST API)

Query any table directly:

| Table | Route |
|-------|-------|
| Campaigns | `/rest/v1/campaigns` |
| Routes (Target Areas) | `/rest/v1/target_areas` |
| Deliveries | `/rest/v1/deliveries` |
| Enquiries | `/rest/v1/enquiries` |
| Team Members | `/rest/v1/team_members` |
| Reservations | `/rest/v1/reservations` |
| Restricted Areas | `/rest/v1/restricted_areas` |
| Demographic Feedback | `/rest/v1/demographic_feedback` |

**Filter examples:**
- `/rest/v1/enquiries?enquiry_date=gte.2026-01-01` - enquiries from Jan 2026 onwards
- `/rest/v1/deliveries?delivery_date=eq.2026-02-15` - deliveries on specific date
- `/rest/v1/enquiries?instructed=eq.true` - only instructed enquiries

---

*Last updated: 2026-02-26*
