# Multi-Agent Coordination Protocol

This project is worked on concurrently by two AI agents: **Claude** (via Claude Code CLI)
and **OpenCode**. This file defines how they coordinate to avoid conflicts.

---

## Rule: Claim Before You Work

Before making any code changes or executing any plan, you MUST claim the work in
`.planning/STATE.md` under `## Active Tasks`.

**This applies to ALL work** — not just formal GSD plan execution. If you are writing
code, editing files, or implementing anything, claim it first.

### Claim format

```
- [AGENT] [scope] — [brief description] — claimed [YYYY-MM-DD HH:MM UTC]
```

- `AGENT` = `Claude` or `OpenCode`
- `scope` = plan ID if running a GSD plan (e.g. `03-01`), or a short label if ad-hoc (e.g. `ad-hoc`)
- Remove your entry when your work is committed/complete

### Example

```
- Claude 03-01 — Delivery recording UI — claimed 2026-02-25 14:30 UTC
- OpenCode ad-hoc — unassign_area RPC — claimed 2026-02-25 14:45 UTC
```

---

## Rule: Check Before You Claim

Before writing your claim, read the current `## Active Tasks` section:

```bash
grep -A 20 "## Active Tasks" .planning/STATE.md
```

If another agent has an active claim that overlaps with your intended work, **stop and
notify the user** rather than proceeding. Do not overwrite another agent's claim.

---

## Rule: Pick the Next Unblocked Task

When starting a session (e.g., running `/gsd-execute-phase`), follow this process:

1. **Check for existing claims** — Read `## Active Tasks` in STATE.md
2. **If your intended work is already claimed** — Stop and tell the user
3. **If no claim exists** — Claim it before starting work
4. **Find unclaimed work** — Look for:
   - Plans without SUMMARY.md (incomplete)
   - The `.continue-here.md` file for current phase context
   - Any ad-hoc tasks not yet started

**Before executing any phase or plan, you MUST verify no other agent has claimed it.**

---

## Rule: Update STATE.md After Every Session

When you finish a session (whether or not it was a formal GSD plan), update STATE.md:

- Remove your claim from `## Active Tasks`
- Update `## Current Position` if phase/plan status changed
- Add any new decisions to `### Decisions`
- Add any new blockers to `### Blockers/Concerns`
- Update `## Session Continuity` with what you did and where you stopped

---

## Why This Exists

GSD was designed for a single AI agent. This project uses two. Without coordination:

- Both agents could edit the same file simultaneously
- One agent could undo the other's work
- STATE.md could have conflicting information

This file is the **single source of truth** for the coordination protocol.
STATE.md `## Active Tasks` is the **live state** of who is doing what right now.

---

## For Claude

Claude should read this file at the start of any session where code changes are planned.
Claude's GSD workflow does not enforce claiming automatically — it must be done manually
or via the instructions given by the user at session start.

## For OpenCode

OpenCode's `execute-plan` workflow includes `claim_task` and `release_task` steps that
implement this protocol automatically for GSD plan execution. For ad-hoc work outside
GSD plans, OpenCode must follow this protocol manually.

**Critical:** At the START of every session, before executing any phase:
1. Read STATE.md `## Active Tasks`
2. Check if your intended work is already claimed
3. If claimed by Claude, do NOT proceed — tell the user
4. If unclaimed, add your claim BEFORE making any code changes
