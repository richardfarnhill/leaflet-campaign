---
created: 2026-02-25T21:30:15.797Z
title: Remove legacy session system and rewire summary stats to deliveries table
area: ui
files:
  - index.html:601-654
  - index.html:2140-2266
---

## Problem

The app still contains a large pre-Phase 4 legacy system based on hardcoded sessions:

- `BASE[]` — hardcoded array of 20 delivery sessions with dates, areas, postcodes, briefings
- `sessions`, `sessionState`, `saveTimers` — in-memory state derived from BASE
- `session_log` table — now dropped (DB audit 2026-02-25)
- `rescheduled_sessions` table — now dropped (DB audit 2026-02-25)
- `render()` — renders session cards (container `#schedule` was removed — already no-ops)
- `scheduleSessionSave()`, `saveSession()` — write to dropped session_log table (will 404)
- `handleMissed()` — writes to dropped rescheduled_sessions table (will 404)
- `updateSummary()` — calculates `td` (total delivered) from `sessionState`, not from `deliveries`
- `calcCompletion()` — projects completion date from session pace

The critical dependency: `updateSummary()` passes `td` (total delivered) and `rem` (remaining)
to `updateFinance()`. Currently `td` is derived from the legacy `sessionState`, not from the
`deliveries` table. This means finance projections are working off stale/wrong data.

## Solution

Phase 1 — rewire `updateSummary()` to use `deliveries` table:
- `td` = SUM(leaflets_delivered) from `deliveries` WHERE campaign_id = currentCampaignId
  (already fetched by `loadAll()` into a global or recalculate inline)
- `rem` = campaign target_leaflets - td
- Progress bar, % complete, summary stats all update from real DB data

Phase 2 — remove dead code:
- Delete `BASE[]`, `sessions`, `sessionState`, `saveTimers` globals
- Delete `render()`, `scheduleSessionSave()`, `saveSession()`, `handleMissed()`
- Delete `calcCompletion()` or rewire to use delivery pace from `deliveries`
- Remove the reforecastMsg / session pace summary UI (or replace with delivery-based version)

Phase 3 — remove TOTAL/DAILY_TARGET hardcoded constants:
- `TOTAL=20000` should come from `campaigns.target_leaflets`
- `DAILY_TARGET=1000` can be derived or removed

## Risk

Medium — `updateSummary()` → `updateFinance()` chain must not break.
Rewire `td` carefully and test finance projections still render correctly after.
