# Project State

**Last updated:** 2026-03-03 (Street enrichment 14/18 done; docs & skill fully overhauled)

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
| Route planning & enrichment skill | `~/.claude/commands/leaflet-plan-routes.md` — use `/leaflet-plan-routes` |
| Street name enrichment skill | `~/.claude/commands/leaflet-enrich-streets.md` — use `/leaflet-enrich-streets` |
| Unresolved open issues | [OPEN-ISSUES.md](./OPEN-ISSUES.md) |
| DB schema | `supabase_schema.sql` |
| Codebase reference | [codebase/](./codebase/) |

---

## Current Position

**Phase:** 10 of 10 (Backlog)
**Status:** Production-ready. All core phases 1-9 complete. Password bypass still in place — re-enable before go-live.

**Last activity:** 2026-03-03 — Street enrichment: 14/18 routes done. 6 still empty: Poynton A/B/C/D, Wilmslow A/B. Use `/leaflet-enrich-streets` to continue.

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

<!-- no active claims -->

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

- **GitHub Pages deployment pipeline** — ✅ **FULLY RESOLVED 2026-02-28** — Two bugs fixed: (1) single-quoted heredoc prevented secret expansion → switched to `printf`; (2) Pages was set to `legacy` build mode (serving raw git branch) instead of `workflow` mode (serving GitHub Actions artifact) → switched via API. `config.js` now live in production with real credentials. See OI-04 in OPEN-ISSUES.md.
- **Re-enable password** before go-live: find `if(false && !getCookie(COOKIE)){` in index.html, remove `false &&`
- **Drop unused table** (optional): `DROP TABLE IF EXISTS campaign_members CASCADE;`
- **14k_Feb_2026 re-plan** — prompt ready at [REPLAN-14K-PROMPT-CORRECTED.md](./REPLAN-14K-PROMPT-CORRECTED.md)
- **Postcode OA lookup** — M, SK, WF, WA loaded; CH, CW, LS, HD, HX, BD, OL, BL, WN, TN, EX still needed — see [POSTCODE_LOAD_STATUS.md](./POSTCODE_LOAD_STATUS.md)
- **Enrich remaining 6 routes with street names** — 12/18 done; 6 still empty: Poynton A/B/C/D, Wilmslow A/B. Run `python scripts/enrich_sequential.py` (1–2 routes at a time; Nominatim 1 req/sec limit — no parallel runs). See ROUTE-PLANNING-ENGINE.md for full notes.

---

## Session Summary (2026-02-28 — GitHub Pages Production Fix — FULLY RESOLVED)

### What was done

**GitHub Pages Deployment Pipeline — OI-04 FULLY RESOLVED**

**Session 1 (initial attempt):**
1. Created `.github/workflows/deploy.yml` — generates `config.js` from GitHub Secrets at build time
2. Added 3 GitHub Secrets via CLI: `SUPABASE_URL`, `SUPABASE_KEY`, `APP_PASSWORD`
3. Fixed upload path (3 attempts — wrong directory → correct repo root)
4. Workflow succeeded (25+ MB artifact) but app still failed

**Session 2 (root cause found and fixed — two bugs):**

**Bug 1 — Shell variable expansion blocked:**
- The heredoc used `<< 'CONFEOF'` (single-quoted delimiter)
- In bash, a single-quoted heredoc delimiter disables ALL variable expansion inside the body
- `$SBU`, `$SBK`, `$APWD` were written literally as those strings into `config.js`
- Fix: replaced heredoc with `printf '...' "$SBU" "$SBK" "$APWD" > config.js`
- Committed as `0adb573`

**Bug 2 — GitHub Pages build mode was `legacy`:**
- `gh api repos/richardfarnhill/leaflet-campaign/pages` showed `"build_type": "legacy"`
- Legacy mode serves directly from the `main` branch via a separate `pages-build-deployment` workflow
- Our Actions workflow uploaded correct artifacts, but Pages was ignoring them and serving raw git (no `config.js`)
- Fix: `gh api --method PUT repos/richardfarnhill/leaflet-campaign/pages -f build_type=workflow`
- Triggered fresh `workflow_dispatch` run → config.js now live

**Verified working:**
```
curl https://richardfarnhill.github.io/leaflet-campaign/config.js
# Returns: const CONFIG = { SUPABASE_URL: "https://tjebidvgvbpnxgnphcrg.supabase.co", ... }
```
Campaign dropdown confirmed working in production. ✅

### What's next

- Run `/leaflet-enrich-streets` to finish remaining routes in 14k_Feb_2026 campaign (6 left: Poynton A/B/C/D, Wilmslow A/B)
- Re-enable password check before production launch (OI-02)

---

## Session Summary (2026-02-28 — OI-01 Resolution)

### What was done

**Street Name Enrichment — OI-01 RESOLVED**

1. **Researched 4 data sources in parallel:**
   - Nominatim (OpenStreetMap) ✓ **Selected**
   - Overpass API ✓ (investigated, fallback option)
   - OS Open Names ✓ (investigated, CSV-based alternative)
   - postcodes.io + Royal Mail PAF ✓ (no free option)

2. **Created Python enrichment script:**
   - `scripts/enrich_sequential.py` — canonical script (superseded initial prototype)
   - Strictly sequential, 1.5s delay between Nominatim requests
   - Uses Supabase REST API directly (no pip package required)
   - Idempotent: only targets zero-street routes, safe to re-run

3. **Created new Claude skill:**
   - `/leaflet-enrich-streets` — High-level orchestration for route enrichment
   - Documents Nominatim method, rate limiting, edge cases
   - Integrated with existing `/leaflet-plan-routes` skill

4. **Tested on E2E Test Route:**
   - Before: `streets: []` (empty)
   - After: `streets: ["Dewsbury Road"]` (fetched from Nominatim)
   - Status: ✅ Verified in DB via SQL

5. **Updated all affected docs:**
   - ROUTE-FLAGGING.md: corrected street extraction method
   - leaflet-plan-routes.md: pointed to Nominatim, `/leaflet-enrich-streets`
   - OPEN-ISSUES.md: marked OI-01 as resolved with implementation details

### What's next

- Run `/leaflet-enrich-streets` to finish remaining routes in 14k_Feb_2026 campaign (6 left: Poynton A/B/C/D, Wilmslow A/B)
- ~~Optional: test OS Open Names CSV method~~ — resolved with Nominatim; no further action needed

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
