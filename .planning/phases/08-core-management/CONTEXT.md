# Phase 8 Context

## Previous Phase
Phase 7 delivered: route deletion UI, RLS policies, security credentials in config.js

## What's Different Now
- Route cards need street names and boundary display
- Need API endpoint for delivery stats (monthly, last 30 days)
- Auto-assign enquiries to routes for better leaderboard

## Key Context for Phase 8
1. **Stats API needed** - monthly totals, last 30 days for external reporting
2. **Route lifecycle** - deletion should trigger new route creation prompt
3. **Enquiry attribution** - link enquiries to routes for leaderboard accuracy

## Supabase Schema Reference
Key tables: campaigns, target_areas, deliveries, enquiries, team_members, reservations, restricted_areas, demographic_feedback (new)

## Files to Modify
- index.html (most tasks)
- supabase_schema.sql (new tables/functions)
- config.js (if needed)

## Testing Approach
- Manual testing in browser
- Check API response via network tab
