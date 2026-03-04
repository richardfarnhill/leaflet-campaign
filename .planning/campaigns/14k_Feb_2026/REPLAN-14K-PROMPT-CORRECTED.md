# Route Planning Prompt — 14k_Feb_2026 Campaign (CORRECTED)

## Context

Campaign `14k_Feb_2026` (ID: `10c1ee37-3e33-48b8-85ed-c5da41771b18`) has been cleaned up:
- **14 non-completed routes deleted** ✓
- **1 completed route preserved:** Wilmslow — Dean Row (kickoff), SK9 2BY, 600 leaflets delivered, status: completed
- **Remaining budget:** 13,400 leaflets (14,000 − 600)

## Authoritative Rules (from ROUTE-FLAGGING.md & REQUIREMENTS.md)

**Route Size:** 500–1,000 doors (Census households, rounded to nearest 50)
- Target midpoint: 750 doors per route
- If enrichment reveals > 1,000 doors: split into A/B before writing to DB

**Global Exclusions (2-mile radius each):**
- WA14 1QP (Altrincham office)
- SK4 4QG (Stockport exclusion 1)
- SK4 4DT (Stockport exclusion 2)
- OL10 4NN (Heywood exclusion)

**Demographic Filter:** Owner-occupied ≥ 60%

**Data Sources (VERIFIED PATTERNS 2026-02-27):**
- Unit postcodes + OA21 codes: postcodes.io `/postcodes?q={sector}&limit=100`
- Household counts + owner-occupied %: NOMIS NM_2072_1 (TS054 Tenure)
  - Household count: `?geography=E00...,E00...&c2021_tenure_9=0&measures=20100`
  - Owner-occupied %: `?geography=E00...,E00...&c2021_tenure_9=1001&measures=20301`
  - **Alpha OA codes work directly** — NO def.sdmx.json lookup needed
  - Batch up to 100 codes per request

## Task: Re-plan Routes Using Mode A

**Use `/leaflet-plan-routes` skill with these parameters:**

```
Campaign: 14k_Feb_2026 (ID: 10c1ee37-3e33-48b8-85ed-c5da41771b18)
Budget: 13,400 leaflets remaining
Route size: 500–1,000 doors (target: 750)
Demographic filter: ≥60% owner-occupied
Global exclusions: WA14 1QP, SK4 4QG, SK4 4DT, OL10 4NN (all 2-mile radius)

Areas to plan (all Cheshire/South Manchester suburbs):
— Wilmslow (SK9, excluding SK9 2 which is the completed route)
— Knutsford (WA16)
— Lymm (WA13)
— Stretch to nearby areas as needed to reach 13,400 budget (e.g. Handforth SK9 3, Cheadle Hulme SK8, Bramhall SK7, Poynton SK12, East Didsbury M20)
```

**Process:**
1. Resolve each area to postcodes via postcodes.io `/places` and `/postcodes?q={sector}`
2. Group postcodes by OA21 code (unique OAs)
3. Fetch household counts + owner-occupied % from NOMIS NM_2072_1 (batched, 100 codes at a time)
4. Apply demographic filter (≥60% owner-occupied) and exclusion radius checks (Turf.js)
5. Chunk remaining OAs into routes of 500–1,000 doors (target: 750)
6. Present plan as table (route name, sectors, doors, owner-occ%, include?)
7. User approves/adjusts
8. Insert approved routes into DB:
   - `POST /rest/v1/target_areas` — create route cards
   - `POST /rest/v1/route_postcodes` — bulk insert postcode data with OA21 codes and household counts

**Success criteria:**
- All routes 500–1,000 doors (rounded to nearest 50)
- Total doors ≈ 13,400 or close to budget
- All routes pass demographic (≥60% owner-occ) and exclusion filters
- Plan presented and approved before DB insert

## Completed Route (DO NOT MODIFY)

```
ID: 8f55161f-e9b3-4c3f-9a0d-49c785f09d0e
Name: Wilmslow — Dean Row (kickoff)
Postcode: SK9 2BY
Status: completed
Leaflets delivered: 600
House count: 500 (rounded)
```

Exclude SK9 2 sector from Wilmslow re-plan to avoid overlap with this completed area.

## Key Documents

- `.planning/ROUTE-FLAGGING.md` — authoritative rules, data sources, NOMIS patterns
- `.planning/ROUTE-PLANNING-ENGINE.md` — full technical spec for Mode A
- `~/.claude/commands/leaflet-plan-routes.md` — skill documentation with updated NOMIS patterns

---

**Ready to execute. Copy this prompt into a new Claude Code window and run the skill.**
