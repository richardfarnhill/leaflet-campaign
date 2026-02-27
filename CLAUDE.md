# Project Instructions for Claude

## Multi-Agent Coordination

This project is worked on concurrently by Claude and OpenCode.

**At the start of every session:**

1. Read `.planning/COORDINATION.md` — full protocol lives here
2. Read `.planning/STATE.md` — current position, decisions, outstanding items
3. Check `## Active Tasks` in STATE.md — if OpenCode has claimed your intended work, stop and tell the user
4. Find unclaimed work: plans without SUMMARY.md, `.continue-here.md`, or ad-hoc tasks
5. Claim your work before touching any files:
   `- Claude [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC]`
6. Remove your claim from STATE.md when your work is committed

---

## Key Reference Documents

STATE.md contains a full navigation table. Quick reference:

| Task | Document |
|------|---------|
| Understand the project | `.planning/PROJECT.md` |
| Check requirements | `.planning/REQUIREMENTS.md` |
| Find a phase plan | `.planning/phases/{N}-{name}/{N}-01-PLAN.md` |
| Route enrichment rules | `.planning/ROUTE-FLAGGING.md` |
| Route planning engine spec | `.planning/ROUTE-PLANNING-ENGINE.md` |
| Run route planning / enrichment | `~/.claude/commands/leaflet-plan-routes.md` (skill) |
| Postcode OA lookup load progress | `.planning/POSTCODE_LOAD_STATUS.md` |
| 14k campaign re-plan prompt | `.planning/REPLAN-14K-PROMPT-CORRECTED.md` |
| Unresolved issues & concerns | `.planning/OPEN-ISSUES.md` |
| DB schema | `supabase_schema.sql` |
| Codebase analysis | `.planning/codebase/` |

---

## Project Context

Single-file app (`index.html`). No build system. Supabase backend.
Shell is **Git Bash on Windows** — use Unix syntax, Windows paths (`c:/Users/richa/...`), never `/tmp`.
Python available via `python "c:/path/to/script.py"`.
Supabase MCP tools: `mcp__claude_ai_Supabase__execute_sql` / `mcp__claude_ai_Supabase__apply_migration`.
Project ref: `tjebidvgvbpnxgnphcrg`.
