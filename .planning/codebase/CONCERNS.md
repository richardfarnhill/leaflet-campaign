# Codebase Concerns

**Analysis Date:** 2026-02-25

## Security Issues

**Hardcoded Credentials:**
- Issue: Password `WillsX2025!` and Supabase JWT key embedded in JavaScript source
- Files: `index.html` lines 9, 134-135
- Impact: Anyone viewing source can access Supabase backend
- Fix approach: Move to proper auth system or environment variables

**No Role-Based Access:**
- Issue: Single password grants full read/write access
- Files: `index.html` lines 7-19
- Impact: No way to have read-only users or admin vs user roles
- Fix approach: Implement Supabase Auth with RLS policies

## Architecture Issues

**Monolithic Single File:**
- Issue: 414 lines of mixed HTML, CSS, JavaScript in one file
- Files: `index.html`
- Impact: Hard to maintain, test, or extend
- Fix approach: Split into `index.html`, `styles.css`, `app.js` (per IMPLEMENTATION_PLAN.md)

**No Build System:**
- Issue: No bundling, minification, or transpilation
- Files: None
- Impact: Cannot use TypeScript, modern ES features limited
- Fix approach: Add npm/vite for development

## Data Management Issues

**Hardcoded Session Data:**
- Issue: Campaign schedule (BASE array) hardcoded in source
- Files: `index.html` lines 139-159
- Impact: Changing schedule requires code changes
- Fix approach: Move to Supabase `target_areas` table

**No Offline Support:**
- Issue: App requires network connection to function
- Files: All
- Impact: Cannot work without internet
- Fix approach: Add Service Worker for offline capability

## Error Handling Gaps

**No Network Retry Logic:**
- Issue: Single failed request shows error, no retry
- Files: `index.html` lines 192-196 (`sbFetch`)
- Impact: Transient network issues cause failures
- Fix approach: Add exponential backoff retry

**Silent Failures Possible:**
- Issue: JSON parse errors not handled gracefully
- Files: `index.html` line 195
- Impact: Malformed responses could break app
- Fix approach: Add try-catch around JSON.parse

## State Management Issues

**In-Memory State Only:**
- Issue: `sessionState` object lost on page refresh if not saved
- Files: `index.html` lines 189-190
- Impact: User loses unsaved changes on refresh
- Fix approach: Add localStorage persistence as backup

**Race Conditions:**
- Issue: Multiple rapid edits could cause save conflicts
- Files: `index.html` lines 228-236
- Impact: Last write wins, potential data loss
- Fix approach: Add version/timestamp checking

## Maintainability Issues

**No Code Organization:**
- Issue: All functions in global scope
- Files: `index.html`
- Impact: Name collisions, hard to navigate
- Fix approach: Use ES6 modules/classes

**No Documentation:**
- Issue: No JSDoc comments, inline only
- Files: `index.html`
- Impact: Hard for new developers to understand
- Fix approach: Add JSDoc to all functions

## Testing Gaps

**No Tests:**
- Issue: No unit tests, integration tests, or E2E tests
- Files: None exist
- Impact: Bugs only found manually
- Fix approach: Add Vitest/Jest for unit, Playwright for E2E

## Database Schema Issues

**Missing Tables in Current DB:**
- Issue: Code expects `session_log`, `finance_actuals`, but schema defines newer tables
- Files: `index.html` lines 203-206 vs `supabase_schema.sql`
- Impact: Feature mismatch between code and planned schema
- Fix approach: Migrate to new schema per IMPLEMENTATION_PLAN.md

**No Indexes on Legacy Tables:**
- Issue: Schema shows indexes on new tables, but legacy tables may lack them
- Files: `supabase_schema.sql`
- Impact: Performance degradation as data grows
- Fix approach: Add indexes to all query columns

## Scalability Limits

**Client-Side Rendering:**
- Issue: All sessions rendered at once
- Files: `index.html` lines 268-314
- Impact: Performance issues with large session counts
- Fix approach: Implement pagination/virtual scrolling

**No Caching:**
- Issue: Every page load fetches all data
- Files: `index.html` lines 199-226
- Impact: Slow load times, unnecessary API calls
- Fix approach: Add etag/If-None-Match support

---

*Concerns audit: 2026-02-25*
