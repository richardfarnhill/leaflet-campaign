# Open Issues

**Project:** Leaflet Campaign Tracker
**Last updated:** 2026-02-28
**Purpose:** Canonical register of unresolved concerns, contradictions, and open questions. Update this file when issues are discovered or resolved.

---

## OI-04 — Campaign Dropdown Fails in GitHub Pages Production (RESOLVED ✅ 2026-02-28)

**Status:** FULLY RESOLVED and user-verified working in production
**Resolved by:** Claude (commits `0adb573` + API call to switch Pages build mode)
**Affects:** GitHub Pages deployment, production build pipeline

### The Issue

Campaign dropdown worked in dev but failed on the live GitHub Pages site (`https://richardfarnhill.github.io/leaflet-campaign/`):
- `config.js` is in `.gitignore` (contains Supabase credentials) — so it never gets committed to git
- Without `config.js`, the global `CONFIG` object is undefined → `sbFetch()` calls `fetch(undefined + path)` → all API calls fail
- Symptom: campaign dropdown shows "Failed to Load..." and stays empty

### Root Causes (Two Bugs)

**Bug 1 — Single-quoted heredoc blocked secret expansion:**

The workflow generated `config.js` using:
```bash
cat > config.js << 'CONFEOF'
const CONFIG = {
  SUPABASE_URL: '$SBU',   ← written literally as "$SBU", not the secret value
  ...
};
CONFEOF
```
In bash, a single-quoted heredoc delimiter (`<< 'EOF'`) disables ALL variable expansion inside the body. The file was created with the literal string `$SBU` instead of the Supabase URL.

**Bug 2 — GitHub Pages was in `legacy` build mode:**

Running `gh api repos/richardfarnhill/leaflet-campaign/pages` revealed `"build_type": "legacy"`. In legacy mode, GitHub Pages serves content directly from the `main` branch (via a separate auto-triggered `pages-build-deployment` workflow). Our GitHub Actions workflow was successfully uploading artifacts with a correct `config.js`, but Pages was **ignoring those artifacts** and serving the raw git tree instead — where `config.js` doesn't exist.

This is why `config.js` returned 404 even after a successful workflow run.

### The Fix

**Fix 1 — `printf` instead of heredoc** (commit `0adb573`):
```bash
printf '// Auto-generated from GitHub Secrets\n// DO NOT EDIT\nconst CONFIG = {\n  SUPABASE_URL: "%s",\n  SUPABASE_KEY: "%s",\n  APP_PASSWORD: "%s"\n};\n' "$SBU" "$SBK" "$APWD" > config.js
```
`printf` with double-quoted arguments expands `$SBU` etc. correctly.

**Fix 2 — Switch Pages build mode to `workflow`**:
```bash
gh api --method PUT repos/richardfarnhill/leaflet-campaign/pages -f build_type=workflow
gh workflow run deploy.yml   # trigger fresh deployment
```
Now GitHub Pages only serves content from our Actions artifact, not the raw branch.

### Deployment Architecture (Current)

```
git push to main
    └─→ .github/workflows/deploy.yml triggers
            ├─ Checkout code
            ├─ Generate config.js from GitHub Secrets (printf, no heredoc)
            ├─ actions/configure-pages@v4
            ├─ actions/upload-pages-artifact@v3  (includes generated config.js)
            └─ actions/deploy-pages@v4
                    └─→ https://richardfarnhill.github.io/leaflet-campaign/ updated
```

GitHub Secrets in repo:
- `SUPABASE_URL` — Supabase project URL
- `SUPABASE_KEY` — JWT anon key
- `APP_PASSWORD` — app access password (see config.js locally)

### Verification

```
curl https://richardfarnhill.github.io/leaflet-campaign/config.js
# Returns:
# const CONFIG = {
#   SUPABASE_URL: "https://tjebidvgvbpnxgnphcrg.supabase.co",
#   SUPABASE_KEY: "eyJ...",
#   APP_PASSWORD: "..."
# };
```

✅ `config.js` is 404-free in production
✅ Campaign dropdown loads correctly (user-confirmed)
✅ All Supabase API calls working

### Lessons Learned

- `<< 'HEREDOC'` (single-quoted) = no variable expansion. `<< HEREDOC` (unquoted) = expansion enabled. Use `printf` when in doubt.
- GitHub Pages has two modes: `legacy` (raw branch) and `workflow` (Actions artifact). Check `build_type` via API if workflow succeeds but site doesn't update.
- `upload-pages-artifact` tars from disk — gitignored files that exist on disk ARE included.

### Related Files

- Workflow: `.github/workflows/deploy.yml`
- Previous related issue: OI-02 (password bypass before go-live)

---

## OI-01 — Street Name Source (RESOLVED ✅ 2026-02-28)

**Status:** RESOLVED — Nominatim reverse geocoding is the solution
**Resolved by:** Claude via research + implementation
**Affects:** `target_areas.streets` enrichment (Mode B), [ROUTE-FLAGGING.md](./ROUTE-FLAGGING.md), [ROUTE-PLANNING-ENGINE.md](./ROUTE-PLANNING-ENGINE.md), `~/.claude/commands/leaflet-plan-routes.md`

### The Issue (Now Resolved)

Multiple documents incorrectly claimed `target_areas.streets` was populated from postcodes.io `thoroughfare` field, which **does not exist** in the API response.

### The Solution

**Use Nominatim reverse geocoding** (OpenStreetMap):
- Free, CORS-safe, no API key required
- `GET https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json`
- Returns `address.road` — the street name
- Rate limit: 1 req/sec (manageable for ~534 postcodes = ~9 min)

### Implementation

1. **Canonical Python script:** `scripts/enrich_sequential.py`
   - Fetches all zero-street routes for the campaign via Supabase REST API
   - Calls Nominatim for each postcode (1.5s delay between requests)
   - Deduplicates and sorts street names
   - Updates `target_areas.streets` after each route completes (safe to interrupt)
   - Run from project root: `python scripts/enrich_sequential.py`
   - **Do NOT run in parallel** — Nominatim bans concurrent requests with 429s

2. **Claude skill:** `/leaflet-enrich-streets`
   - Orchestrates the enrichment process
   - Contains full usage instructions, troubleshooting, and single-route inline script
   - Located at `~/.claude/commands/leaflet-enrich-streets.md`

3. **Updated docs:**
   - leaflet-plan-routes.md: Now points to Nominatim method, `/leaflet-enrich-streets` skill
   - ROUTE-FLAGGING.md: Updated table + street extraction section
   - This file: OI-01 marked as resolved

### Verification

✅ E2E test successful:
- Route: "E2E Test Route" (WF3 1AA)
- Before: `streets: []`
- After: `streets: ["Dewsbury Road"]`
- Status: Updated in DB (confirmed via SQL query)

### Known Limitations

- Rate-limited to 1 req/sec (Nominatim policy)
- Some postcodes (PO boxes, rural) may not return a street
- Data reflects OpenStreetMap accuracy (may lag new developments)

---

## OI-02 — Password Bypass in Production Code ⚠️

**Status:** Known, intentional (testing) — must fix before go-live
**Affects:** `index.html` line ~24 (IIFE)

The password check is bypassed with `if(false && !getCookie(COOKIE)){`. Remove `false &&` before going live.

---

## OI-03 — route_postcodes Sector Overlap

**Status:** Known limitation, deferred to Planning Screen v2
**Affects:** `14k_Feb_2026` campaign, all routes sharing a sector

Routes that share a postcode sector (e.g. two routes both in SK9 3) received identical postcode sets during the ONSPD backfill. Proper per-route geographic boundary definition is deferred to Planning Screen v2 (Phase 10 T5).

---

## Resolved Issues (archive)

| ID | Issue | Resolution | Date |
|----|-------|------------|------|
| — | Phase 9 T2b trigger not implemented | Deployed and tested — `trg_enrich_demographic_feedback` confirmed working | 2026-02-26 |
| — | NOMIS enrichment silent failure (`created_at` vs `recorded_at`) | Fixed column name in ORDER BY | 2026-02-26 |
| — | RLS UPDATE policy missing on demographic_feedback | Policy added | 2026-02-26 |
