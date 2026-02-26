# API Endpoints Documentation

This file documents all Supabase API endpoints used by the Leaflet Campaign application.

---

## RPC Functions (PostgreSQL)

### `get_delivery_stats`

**Type:** RPC (Remote Procedure Call)  
**Route:** `/rest/v1/rpc/get_delivery_stats`  
**Method:** POST

**Description:** Returns aggregated delivery and financial statistics, optionally filtered by campaign and date range.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| p_campaign_id | UUID | No | Filter stats by specific campaign. If null, returns all campaigns. |
| p_start_date | DATE | No | Filter by start date (e.g. '2025-12-01' for December 2025). If provided without end_date, uses full month. |
| p_end_date | DATE | No | Filter by end date (e.g. '2025-12-31'). |

**Date Filtering Examples:**
- `?p_start_date=2025-12-01` → December 2025 (full month)
- `?p_start_date=2026-01-01&p_end_date=2026-03-31` → Q1 2026
- `?p_start_date=2026-02-01` → February 2026 (full month)

**Returns:** JSON object with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| total_leaflets_all_time | BIGINT | Total leaflets delivered across all time |
| leaflets_last_30_days | BIGINT | Leaflets delivered in the last 30 days |
| leaflets_in_period | BIGINT | Leaflets delivered in the filtered date period |
| period_start | DATE | Start date of filtered period |
| period_end | DATE | End date of filtered period |
| routes_completed_count | BIGINT | Number of routes with status 'completed' |
| active_routes_count | BIGINT | Number of routes with status 'reserved' |
| total_revenue | NUMERIC | Sum of instruction_value from instructed enquiries (all time) |
| revenue_in_period | NUMERIC | Sum of instruction_value in filtered date period |
| revenue_per_100_leaflets | NUMERIC | Revenue generated per 100 leaflets delivered |
| enquiries_count | BIGINT | Total number of enquiries (all time) |
| enquiries_in_period | BIGINT | Number of enquiries in filtered date period |
| cases_count | BIGINT | Number of instructed enquiries with value > 0 (all time) |
| cases_in_period | BIGINT | Number of instructed enquiries with value > 0 in period |
| conversion_rate | NUMERIC | Percentage of enquiries that became cases |
| average_case_value | NUMERIC | Average value per instructed case |
| campaign_target | NUMERIC | Campaign target leaflet count |
| delivered_so_far | NUMERIC | Total leaflets delivered |
| projected_revenue_remaining | NUMERIC | Projected revenue for remaining leaflets |

**Example Request:**
```javascript
const stats = await sbFetch('/rest/v1/rpc/get_delivery_stats?p_campaign_id=XXX');
```

**Example Response:**
```json
{
  "total_leaflets_all_time": 15000,
  "leaflets_last_30_days": 3500,
  "routes_completed_count": 12,
  "active_routes_count": 5,
  "total_revenue": 45000.00,
  "revenue_per_100_leaflets": 300.00,
  "enquiries_count": 150,
  "enquiries_last_30_days": 45,
  "cases_count": 25,
  "conversion_rate": 16.67,
  "average_case_value": 1800.00,
  "campaign_target": 30000,
  "delivered_so_far": 15000,
  "projected_revenue_remaining": 45000.00
}
```

---

## REST Endpoints (Tables)

### Campaigns

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/campaigns` | Get all campaigns |
| Get one | GET | `/rest/v1/campaigns?id=eq.{id}` | Get specific campaign |
| Create | POST | `/rest/v1/campaigns` | Create new campaign |
| Update | PATCH | `/rest/v1/campaigns?id=eq.{id}` | Update campaign |
| Delete | DELETE | `/rest/v1/campaigns?id=eq.{id}` | Delete campaign |

### Target Areas (Routes)

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/target_areas` | Get all routes |
| Get by campaign | GET | `/rest/v1/target_areas?campaign_id=eq.{id}` | Get routes for campaign |
| Create | POST | `/rest/v1/target_areas` | Create new route |
| Update | PATCH | `/rest/v1/target_areas?id=eq.{id}` | Update route |
| Delete | DELETE | `/rest/v1/target_areas?id=eq.{id}` | Delete route |

### Deliveries

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/deliveries` | Get all deliveries |
| Get by campaign | GET | `/rest/v1/deliveries?campaign_id=eq.{id}` | Get deliveries for campaign |
| Create | POST | `/rest/v1/deliveries` | Record new delivery |
| Update | PATCH | `/rest/v1/deliveries?id=eq.{id}` | Update delivery |
| Delete | DELETE | `/rest/v1/deliveries?id=eq.{id}` | Delete delivery |

### Enquiries

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/enquiries` | Get all enquiries |
| Get by campaign | GET | `/rest/v1/enquiries?campaign_id=eq.{id}` | Get enquiries for campaign |
| Create | POST | `/rest/v1/enquiries` | Create new enquiry |
| Update | PATCH | `/rest/v1/enquiries?id=eq.{id}` | Update enquiry |
| Delete | DELETE | `/rest/v1/enquiries?id=eq.{id}` | Delete enquiry |

### Team Members

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/team_members` | Get all team members |
| Create | POST | `/rest/v1/team_members` | Add team member |
| Update | PATCH | `/rest/v1/team_members?id=eq.{id}` | Update team member |
| Delete | DELETE | `/rest/v1/team_members?id=eq.{id}` | Remove team member |

### Reservations

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/reservations` | Get all reservations |
| Create | POST | `/rest/v1/reservations` | Create reservation |
| Update | PATCH | `/rest/v1/reservations?id=eq.{id}` | Update reservation |
| Delete | DELETE | `/rest/v1/reservations?id=eq.{id}` | Cancel reservation |

### Restricted Areas

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/restricted_areas` | Get all restricted areas |
| Create | POST | `/rest/v1/restricted_areas` | Add restricted area |
| Update | PATCH | `/rest/v1/restricted_areas?id=eq.{id}` | Update restricted area |
| Delete | DELETE | `/rest/v1/restricted_areas?id=eq.{id}` | Remove restricted area |

### Demographic Feedback

| Operation | Method | Route | Description |
|-----------|--------|-------|-------------|
| List all | GET | `/rest/v1/demographic_feedback` | Get all demographic records |
| Create | POST | `/rest/v1/demographic_feedback` | Record demographic data |

---

## Query Parameters

All REST endpoints support standard Supabase query parameters:

| Parameter | Example | Description |
|-----------|---------|-------------|
| `select` | `?select=id,name` | Select specific columns |
| `eq` | `?id=eq.123` | Filter: equals |
| `gt` | `?value=gt.100` | Filter: greater than |
| `lt` | `?value=lt.100` | Filter: less than |
| `order` | `?order=created_at.desc` | Sort results |
| `limit` | `?limit=10` | Limit results |
| `offset` | `?offset=5` | Paginate results |

---

## External API Access

The Supabase API can be called externally (from scripts, tools, or other services). The **anon key** is public and available in `config.js`.

**Base URL:** `https://tjebidvgvbpnxgnphcrg.supabase.co`

**Anon Key:** Get from `config.js` → `CONFIG.SUPABASE_KEY`

**Example: cURL**
```bash
curl -X POST \
  'https://tjebidvgvbpnxgnphcrg.supabase.co/rest/v1/rpc/get_delivery_stats?p_start_date=2026-02-01' \
  -H 'apikey: <YOUR_ANON_KEY>' \
  -H 'Authorization: Bearer <YOUR_ANON_KEY>'
```

**Example: JavaScript (Node.js)**
```javascript
const fetch = require('node-fetch');

const API_URL = 'https://tjebidvgvbpnxgnphcrg.supabase.co';
const ANON_KEY = '<YOUR_ANON_KEY>'; // Get from config.js

async function getStats(startDate, endDate) {
  const params = new URLSearchParams();
  if (startDate) params.append('p_start_date', startDate);
  if (endDate) params.append('p_end_date', endDate);
  
  const response = await fetch(`${API_URL}/rest/v1/rpc/get_delivery_stats?${params}`, {
    method: 'POST',
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
      'Content-Type': 'application/json'
    }
  });
  return response.json();
}

// Usage examples:
getStats('2026-02-01')                    // February 2026
getStats('2026-01-01', '2026-03-31')      // Q1 2026
getStats()                                 // All time
```

**Example: Python**
```python
import requests

API_URL = 'https://tjebidvgvbpnxgnphcrg.supabase.co'
ANON_KEY = '<YOUR_ANON_KEY>'  # Get from config.js

def get_stats(start_date=None, end_date=None):
    params = {}
    if start_date: params['p_start_date'] = start_date
    if end_date: params['p_end_date'] = end_date
    
    response = requests.post(
        f'{API_URL}/rest/v1/rpc/get_delivery_stats',
        params=params,
        headers={
            'apikey': ANON_KEY,
            'Authorization': f'Bearer {ANON_KEY}'
        }
    )
    return response.json()

# Usage:
print(get_stats('2026-02-01'))  # February 2026
print(get_stats('2026-01-01', '2026-03-31'))  # Q1 2026
```

---

*Last updated: 2026-02-26*
