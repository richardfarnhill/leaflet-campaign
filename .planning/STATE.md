# Project State

**Last updated:** 2026-02-27 (v1.1 release)

---

## Key Documents

| What you need | Where to find it |
|---------------|-----------------|
| Project vision & goals | [PROJECT.md](./PROJECT.md) |
| Feature requirements | [REQUIREMENTS.md](./REQUIREMENTS.md) |
| Phase plan & progress | [ROADMAP.md](./ROADMAP.md) |
| Multi-agent coordination protocol | [COORDINATION.md](./COORDINATION.md) |
| Route enrichment rules (what/when/why) | [ROUTE-FLAGGING.md](./ROUTE-FLAGGING.md) |
| Route planning engine technical spec | [ROUTE-PLANNING-ENGINE.md](./ROUTE-PLANNING-ENGINE.md) |
| Route planning & enrichment skill | `~/.claude/commands/leaflet-plan-routes.md` |
| Street name research prompt (OI-01) | [STREET-NAMES-RESEARCH-PROMPT.md](./STREET-NAMES-RESEARCH-PROMPT.md) |
| Unresolved open issues | [OPEN-ISSUES.md](./OPEN-ISSUES.md) |
| DB schema | `supabase_schema.sql` |
| Codebase reference | [codebase/](./codebase/) |

---

## Current Position

**Phase:** 10 of 10 (Backlog)
**Status:** Production-ready. All core phases 1-9 complete. Password bypass still in place — re-enable before go-live.

**Last activity:** 2026-02-27 — 17 routes planned and inserted for 14k_Feb_2026 campaign (13,450 doors, avg 89% owner-occ). Streets left empty pending street-name extraction fix from other agent.

**Progress:** `[████████████████████░░] 95%` (9/9 core phases + polish)

---

## Architectural Decisions

- No user roles — anyone can reserve, complete, or reassign any area
- Completed cards hidden from grid — only available/reserved shown
- Optional dual team member assignment per area (1 or 2 team members)
- **Single-file app** (`index.html`) — no build system, keep it that way
- UI says "Routes" (renamed from "Areas" in Phase 4); DB table stays `target_areas`
- Geocoding uses postcodes.io (free, no key) — planned from day 1
- Map shows all routes as circle markers (grey=available, amber=reserved, green=completed)
- Team members are route-level, not campaign-level — assigned on individual route cards
- "All Campaigns" view exists via dropdown; campaign-level is the default

---

## Active Tasks

<!-- Multi-agent coordination — see COORDINATION.md for full protocol.
     REQUIRED: Claim here before making ANY code changes. Remove when done.
     Format: - [AGENT] [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC] -->

None.

---

## Phase 7 Task Checklist

| Task | Status | Notes |
|------|--------|-------|
| T1: Route card details — street names, map boundary | ✅ Done | Streets toggle (▼); Map button highlights route postcodes |
| T2: Route deletion UI | ✅ Done | Delete button, confirmation modal, cascades |
| T3: RLS policies verification | ✅ Done | RLS enabled on all tables |
| T4: Route completion — explicit leaflet count + rolling adjustment | ✅ Done | Modal requires count, saves to DB |
| T5: Security — move credentials to config.js | ✅ Done | |
| T6: DB-driven Summary Bar fix (CFG-03) | ✅ Done | |
| T7: Phase review | ✅ Done | P7 fully closed |

---

## Phase 8 Task Checklist

| Task | Status | Notes |
|------|--------|-------|
| T1: Create campaign — enhance with route creation questions | ✅ Done | Two-step modal |
| T2: Global exclusion areas review | ✅ Done | Table, UI CRUD, map circles, global scope |
| T3: Prompt new route when 500 houses short | ✅ Done | `checkAndPromptRouting()` — see ROUTE-FLAGGING.md |
| T4: Auto-assign enquiries to routes | ✅ Done | Two-step modal, geocode + auto-match route |
| T4c: oa21_code written to demographic_feedback inline | ✅ Done | From postcodes.io geocode response |
| T5: API endpoints (Supabase) | ✅ Done | RPC function in supabase_schema.sql |
| T6: Demographic feedback table from enquiries | ✅ Done | Auto-captures instructed enquiries |
| T7: Backfill route_postcodes for 14k_Feb_2026 | ✅ Done | 4,596 rows via ONSPD Nov 2025 |
| T8: Testing procedure | ✅ Done | tests/test-runner.html |
| T9: Demographic enrichment | ✅ Superseded | Replaced by Phase 9 |
| T10: Phase Review & Audit | ✅ Done | P8 complete |

---

## Phase 9 Task Checklist (Demographic Enrichment — Option B)

| Task | Status | Notes |
|------|--------|-------|
| T1: enrichDemographicFeedback() function | ✅ Done | Browser JS fetches owner_occupied_pct from NOMIS |
| T2: Hook into enquiry save | ✅ Done | Called after demographic_feedback INSERT |
| T2b: Server-side trigger (CRITICAL) | ✅ Done | `trg_enrich_demographic_feedback` deployed + tested |
| T3: Test complete enrichment flow | ✅ Done | Bulk + UI paths verified |
| T4: Backfill script | ✅ Done | scripts/backfill_demographics.js |
| T5: Validate & run backfill | ✅ Done | All existing rows enriched |
| T6: Phase review + docs update | ✅ Done | Phase 9 complete |

---

## Phase 10 Task Checklist (Backlog)

| Task | Status | Notes |
|------|--------|-------|
| T1: Dark mode toggle (system default) | ⏳ Pending | |
| T2: CSV/Sheets export | ⏳ Pending | |
| T3: Gmail notifications | ⏳ Pending | |
| T4: Full ClickUp integration | ⏳ Pending | |
| T5: Planning screen v2 | ⏳ Pending | |
| T6: Investigate HuggingFace Postcodes space | ⏳ Pending | https://huggingface.co/spaces/Alealejandrooo/Postcodes |

---

## Outstanding Items

- **Re-enable password** before go-live: find `if(false && !getCookie(COOKIE)){` in index.html, remove `false &&`
- **Drop unused table** (optional): `DROP TABLE IF EXISTS campaign_members CASCADE;`
- **14k_Feb_2026 re-plan** — prompt ready at [REPLAN-14K-PROMPT-CORRECTED.md](./REPLAN-14K-PROMPT-CORRECTED.md)
- **Postcode OA lookup** — M, SK, WF, WA loaded; CH, CW, LS, HD, HX, BD, OL, BL, WN, TN, EX still needed — see [POSTCODE_LOAD_STATUS.md](./POSTCODE_LOAD_STATUS.md)
- **Street name source** — unresolved — see [OPEN-ISSUES.md](./OPEN-ISSUES.md)

---

## Session Handoff (2026-02-26 — for reference)

### What was done

- Trigger `trg_enrich_demographic_feedback` confirmed deployed + working
- NOMIS browser fetch confirmed working (no CORS issue)
- Root cause of failed enrichment: `order=created_at.desc` → column is `recorded_at`. Fixed.
- RLS UPDATE policy missing on `demographic_feedback` — added + updated supabase_schema.sql
- Postcode not being saved to demographic_feedback — fixed
- Existing demographic_feedback rows backfilled

### Bug fixes to index.html

- Delivery journal: missing `id` in SELECT → `openEditDelivery('undefined')` crash. Fixed.
- Delivery journal: added Delete button per row
- Financial projections never rendered: `updateFinance()` was dead code. Fixed.
- Revenue attribution: used `target_areas.team_member_1_id` (doesn't exist) → fixed to use deliveries
- Team revenue display: showed `£1,000%` (double-suffix bug). Fixed.
- Password: bypassed with `false &&` for testing. **TODO: re-enable before go-live.**
