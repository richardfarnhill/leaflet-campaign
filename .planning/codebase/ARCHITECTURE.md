# Architecture

**Analysis Date:** 2026-02-25

## Pattern Overview

**Overall:** Single-Page Application (SPA) with monolithic file structure

**Key Characteristics:**
- Single HTML file containing all HTML, CSS, and JavaScript
- Client-side only (no server-side code)
- Supabase as backend-as-a-service
- In-memory state management via JavaScript objects

## Layers

**Presentation Layer:**
- Location: `index.html` lines 21-82 (CSS) and 84-130 (HTML structure)
- Contains: Styles, header, summary bar, schedule container, finance section
- Depends on: None (self-contained)
- Used by: Browser DOM

**Business Logic Layer:**
- Location: `index.html` lines 133-412 (JavaScript)
- Contains: Data handling, calculations, rendering logic, Supabase integration
- Depends on: Supabase REST API
- Used by: Presentation layer via event handlers

**Data Layer:**
- Location: Supabase database (tables: `session_log`, `finance_actuals`, `rescheduled_sessions`)
- Contains: Persistent campaign data
- Accessed via: `sbFetch()` function (lines 192-196)

## Data Flow

**Load Flow:**
1. Page loads → `DOMContentLoaded` event triggers `loadAll()`
2. `loadAll()` calls Supabase REST API for session_log, finance_actuals
3. Response populates `sessionState` object
4. `render()` generates DOM from BASE + sessionState
5. `updateSummary()` calculates totals

**Session Update Flow:**
1. User changes input → `change` event fires
2. Handler updates `sessionState[id][field]`
3. `scheduleSessionSave(id)` debounces (800ms)
4. `saveSession(id)` POSTs to Supabase `session_log`
5. Sync status updates

**Finance Update Flow:**
1. User changes finance input → `input` event fires
2. `scheduleFinanceSave()` debounces (800ms)
3. `saveFinance()` POSTS to Supabase `finance_actuals`
4. `updateFinance()` recalculates projections

## Key Abstractions

**BASE Array:**
- Purpose: Static campaign schedule definition
- Location: `index.html` lines 139-159
- Pattern: Array of session objects with id, dateISO, week, area, postcode, target, briefing

**sessionState Object:**
- Purpose: Dynamic session data from database
- Pattern: `{ [sessionId]: { staff1, staff2, delivered, comment, went_out } }`

**sbFetch Function:**
- Purpose: Supabase REST API wrapper
- Location: `index.html` lines 192-196
- Pattern: Promise-based fetch with auth headers

## Entry Points

**Page Load:**
- Location: `index.html` line 406-411
- Triggers: DOMContentLoaded event
- Responsibilities: Initialize app, load data, set up auto-refresh interval (30s)

**Authentication:**
- Location: `index.html` lines 7-19
- Responsibilities: Password check via cookie (hardcoded password)

## Error Handling

**Strategy:** Basic try-catch with fallback

**Patterns:**
- `loadAll()` has nested try-catch for optional `rescheduled_sessions` table
- Sync status indicator shows connection state
- Error messages displayed in sync bar

## Cross-Cutting Concerns

**Logging:** None - uses sync status indicator instead

**Validation:** Minimal - HTML5 input types (number, text)

**Authentication:**
- Simple cookie-based password (hardcoded in JavaScript line 9)
- NOT secure - credentials visible in source

---

*Architecture analysis: 2026-02-25*
