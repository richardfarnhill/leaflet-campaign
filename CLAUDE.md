# Claude Instructions — Leaflet Campaign Tracker

## Navigation First

**Always read `SOP.md` at the start of a session.** It routes you to the right document for your task.

If you see a doc that contradicts the code, do not assume the code is wrong. Check `SOP.md` → then `STATE.md` → then ask the user.

---

## Critical Environment

| Setting | Value |
|---------|-------|
| **Architecture** | Single file (`index.html`). No build system. No framework. |
| **Backend** | Supabase — project ref `tjebidvgvbpnxgnphcrg` |
| **Shell** | Git Bash on Windows |
| **Paths** | Unix syntax, Windows absolute paths: `c:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/` |
| **Temp files** | Never use `/tmp` — use `c:/Users/richa/AppData/Local/Temp/` or project folder |
| **Python** | `python "c:/path/to/script.py"` — always quote paths |
| **pip** | `python -m pip install ...` |
| **Supabase MCP** | `mcp__claude_ai_Supabase__execute_sql` / `mcp__claude_ai_Supabase__apply_migration` |

---

## Pre-flight Checklist

Run this before touching any file:

- [ ] Read `SOP.md` — confirm your intent and which docs apply
- [ ] Read `.planning/STATE.md` — what is the current project position?
- [ ] Check `## Active Tasks` in STATE.md — is OpenCode already on this?
- [ ] If task is claimed: **STOP** — tell the user, do not overlap
- [ ] Claim your task in STATE.md before making any changes
- [ ] Release your claim when work is committed

---

## Code Standards

**Vanilla-Plus architecture — keep it simple:**

- All logic lives in `index.html`. Section headers like `/* === SECTION: Route Planning === */` are mandatory — the file is 150KB+, navigation matters.
- No new external libraries without user approval.
- All Supabase calls must be wrapped in `try/catch` with visible UI error feedback — there is no build-time safety net.
- Never shadow or conflict with existing global variables. Search the file before adding new ones.
- CSS: inline `<style>` tags or existing styles only. No Tailwind, no CDN additions without approval.
- Test your logic against `supabase_schema.sql` before running — the schema is the contract.

---

## Mandatory Maintenance

These rules exist because doc drift has caused real bugs. They are not optional.

| You change... | You update... | Timing |
|---|---|---|
| DB schema | `supabase_schema.sql` | Before session ends |
| RPC or REST endpoint | `api_endpoints.md` | Before session ends |
| Route rules / NOMIS patterns | `.planning/ROUTES.md` | Before session ends |
| Deployment / workflow | `.github/workflows/deploy.yml` + STATE.md | Before session ends |
| Postcode areas | `.planning/POSTCODE_LOAD_STATUS.md` | Immediately |
| Open issue (new or resolved) | `.planning/OPEN-ISSUES.md` | Immediately |
| Project state | `.planning/STATE.md` | End of session |

---

## Multi-Agent Coordination

Claude and OpenCode work on this project concurrently.

**Claim format:**
```
- Claude [scope] — [description] — claimed YYYY-MM-DD HH:MM UTC
```

**Never start work without claiming.** Never leave a stale claim — remove it when done.

Full coordination protocol: see `SOP.md` → Pre-flight Checklist.

---

## Key Skills

| Skill | Command |
|-------|---------|
| Plan or enrich routes | `/leaflet-plan-routes` |
| Enrich street names (Nominatim) | `/leaflet-enrich-streets` |

---

*Last updated: 2026-03-04*
