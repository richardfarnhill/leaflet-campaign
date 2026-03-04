# API Endpoints — Leaflet Campaign Tracker

**Supabase project:** `tjebidvgvbpnxgnphcrg`
**Base URL:** `https://tjebidvgvbpnxgnphcrg.supabase.co`
**API Key:** Get from Richard (anon key)

> **Maintenance rule:** If you add, modify, or remove any RPC function or REST table, update this file before the session ends.

---

## RPC Functions

### `get_delivery_stats`

**Endpoint:** `POST /rest/v1/rpc/get_delivery_stats`

**Parameters:**

| Parameter | Type | Example | Description |
|-----------|------|---------|-------------|
| `p_campaign_id` | UUID | `10c1ee37-...` | Filter to one campaign. Omit for all campaigns. |
| `p_start_date` | DATE | `2026-02-01` | Period start. If only this is set, defaults to full month. |
| `p_end_date` | DATE | `2026-02-28` | Period end. |

**Response fields:**

| Field | Description |
|-------|-------------|
| `total_leaflets_all_time` | All leaflets ever delivered |
| `leaflets_in_period` | Leaflets in selected date range |
| `leaflets_last_30_days` | Leaflets in last 30 days |
| `routes_completed_count` | Completed routes (status = 'completed') |
| `active_routes_count` | Reserved routes (status = 'reserved') |
| `total_revenue` | Total instruction value £ (all time) |
| `revenue_in_period` | Instruction value £ in date range |
| `revenue_per_100_leaflets` | £ per 100 leaflets (all time) |
| `enquiries_count` | Total enquiries (all time) |
| `enquiries_in_period` | Enquiries in date range |
| `enquiries_last_30_days` | Enquiries in last 30 days |
| `cases_count` | Total instructed cases (all time) |
| `cases_in_period` | Cases in date range |
| `conversion_rate` | % of enquiries instructed |
| `average_case_value` | Average £ per instructed case |
| `campaign_target` | Target leaflets for campaign(s) |
| `delivered_so_far` | Total delivered (same as total_leaflets_all_time) |
| `projected_revenue_remaining` | Estimated revenue from remaining leaflet budget |
| `period_start` | Echo of p_start_date |
| `period_end` | Echo of p_end_date |

**Example queries:**

```
# All campaigns, all time
GET /rest/v1/rpc/get_delivery_stats?apikey=YOUR_KEY

# Specific campaign
GET /rest/v1/rpc/get_delivery_stats?p_campaign_id=UUID&apikey=YOUR_KEY

# February 2026
GET /rest/v1/rpc/get_delivery_stats?p_start_date=2026-02-01&p_end_date=2026-02-28&apikey=YOUR_KEY

# Q1 2026
GET /rest/v1/rpc/get_delivery_stats?p_start_date=2026-01-01&p_end_date=2026-03-31&apikey=YOUR_KEY

# Campaign + date range
GET /rest/v1/rpc/get_delivery_stats?p_campaign_id=UUID&p_start_date=2026-01-01&p_end_date=2026-03-31&apikey=YOUR_KEY
```

---

## REST Tables

Query any table directly via Supabase REST API.

### Table Reference

| Table | Endpoint | Key Columns |
|-------|----------|-------------|
| Campaigns | `/rest/v1/campaigns` | `id`, `name`, `target_leaflets`, `is_active`, `needs_routing` |
| Routes (Target Areas) | `/rest/v1/target_areas` | `id`, `campaign_id`, `area_name`, `postcode`, `streets[]`, `house_count`, `status` |
| Route Postcodes | `/rest/v1/route_postcodes` | `id`, `target_area_id`, `postcode`, `oa21_code`, `lat`, `lng`, `owner_occupied_pct`, `household_count` |
| Reservations | `/rest/v1/reservations` | `id`, `target_area_id`, `team_member_1_id`, `delivery_date`, `status` |
| Deliveries | `/rest/v1/deliveries` | `id`, `campaign_id`, `target_area_id`, `delivery_date`, `leaflets_delivered` |
| Enquiries | `/rest/v1/enquiries` | `id`, `campaign_id`, `enquiry_date`, `client_name`, `postcode`, `instructed`, `instruction_value` |
| Cases | `/rest/v1/cases` | `id`, `campaign_id`, `enquiry_id`, `instruction_date`, `instruction_value` |
| Team Members | `/rest/v1/team_members` | `id`, `name`, `is_active` |
| Restricted Areas | `/rest/v1/restricted_areas` | `id`, `postcode_prefix`, `radius_miles`, `label`, `campaign_id` (NULL = global) |
| Demographic Feedback | `/rest/v1/demographic_feedback` | `id`, `campaign_id`, `enquiry_id`, `oa21_code`, `postcode`, `owner_occupied_pct`, `instructed`, `instruction_value` |
| Postcode OA Lookup | `/rest/v1/postcode_oa_lookup` | `postcode`, `oa21_code` |

### Filter Examples

```
# Enquiries from Jan 2026 onwards
/rest/v1/enquiries?enquiry_date=gte.2026-01-01

# Instructed enquiries only
/rest/v1/enquiries?instructed=eq.true

# Routes for a specific campaign
/rest/v1/target_areas?campaign_id=eq.{UUID}

# Completed routes
/rest/v1/target_areas?status=eq.completed

# Deliveries on a specific date
/rest/v1/deliveries?delivery_date=eq.2026-02-15

# Postcodes for a specific route
/rest/v1/route_postcodes?target_area_id=eq.{UUID}

# Global restricted areas only
/rest/v1/restricted_areas?campaign_id=is.null

# Global + campaign-specific restricted areas
/rest/v1/restricted_areas?or=(campaign_id.is.null,campaign_id.eq.{UUID})
```

---

## Triggers

### `trg_enrich_demographic_feedback`

Fires `BEFORE INSERT ON demographic_feedback`.

**What it does:**
1. If `oa21_code` is NULL but `postcode` is set: resolves `oa21_code` from `route_postcodes`
2. If `oa21_code` is set: populates `owner_occupied_pct` from `route_postcodes`

**Prerequisite:** `route_postcodes.owner_occupied_pct` must be backfilled from NOMIS first.

---

## Notes for Developers

- **RLS:** Row Level Security is enabled on all tables. Public read access is permitted via anon key. All writes go through the same anon key (no Supabase Auth in use).
- **`cases` table:** Currently tracked via `enquiries.instructed = true` and `enquiries.instruction_value`. The separate `cases` table exists in schema but is not actively used by the UI — all case data is on `enquiries`.
- **`route_postcodes.household_count`:** Stores the OA-level count repeated on every postcode row in that OA. To get true route total: `SUM(DISTINCT oa household_count)`, not `SUM(household_count)`.

---

*Last updated: 2026-03-04*
*Update this file whenever an RPC function or table changes.*
