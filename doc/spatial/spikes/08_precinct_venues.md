# SPIKE 08 — precinct venues: the courtyard and the aerial void

*A design, ruled by Palle 2026-08-13: "precinct bodies get courtyards between
segments, or they get to hang in space above a balcony." Numbers below are
measured from the 192 spine precinct bodies before anything was drawn. Nothing
is implemented; the probe plan is at the end.*

## QUESTION

536 corpus artifacts (192 on the spine) are `containment = precinct`: wider than
the widest slot (12 m) or taller than the certified wall (4.0 m). They cannot
stand in any of the 30 museums *by construction* — `escalation (precinct)` is
the corpus's largest refusal at 186–189 — and today they are routed to `outside`
/ `porch`, venues with no architecture, which the assembler then reports "not
hostable". Two new venues fix this. What exactly are they, who owns each fact,
and which bodies go where?

## THE POPULATION, MEASURED FIRST

```
fits a small court   <= 9 m     51   27%
court                9-17 m     54   28%
grand court         17-34 m     50   26%     -> 155 of 192 (81%) courtyard-servable
beyond any court     > 34 m     37   19%     -> NEITHER venue; see The Tail
posture = float                  4           -> aerial by declaration
heights: median 6.8 m · p90 30 m — and 125 of 192 declare posture `floor`
```

Two facts reshape the brief:

1. **A courtyard has no roof, so it deletes the height refusal.** The 4.0 m
   `CERTIFIED_WALL_M` ceiling is what makes half these bodies precinct at all.
   `foucault_pendulum` (7.6 × 7.6 × **12.04 m**) fits a *small* court. 35
   bodies are tall-but-narrow (h > 8 m, widest ≤ 17 m) and are courtyard
   residents the moment the sky is the ceiling.
2. **Aerial is small and precise, not a second dumping ground.** Exactly 4
   spine bodies declare `float`. The venue is cheap and it should stay
   declaration-driven — widening it by heuristic ("looks like a cloud") is how
   `outside` became a dumping ground.

## THE TWO VENUES

### Courtyard — the corridor exhales

An **unroofed joint between two segments**. The enfilade compresses; the court
releases. One resident per court (v1 — sharing is a later negotiation).

```
   segment N                     COURT                    segment N+1
 ┌───────────┐        ┌───────────────────────┐        ┌───────────┐
 │  interior │ portal │  apron   BODY   apron │ portal │ vestibule │
 │           │══════▶ │   3m   (resident)  3m │══════▶ │           │
 └───────────┘        │       open sky        │        └───────────┘
                      └───────────────────────┘
   walls: low parapet (1.1 m) or none · floor: exterior ground
   walkable: the apron ring · sealed: the resident's body cells
```

Three certified widths, derived from the buckets + a 3 m apron each side,
snapped to the 1 m grid: **COURT_S 15 · COURT_M 23 · COURT_G 40**. The grand
court is wider than the corridor (13–17) — deliberately: the court is the wide
moment, and the corridor re-narrows after. Depth = resident depth + 2 × apron.

### Aerial — the body hangs, the walker keeps the rail

A segment whose floor is **absent beyond a balcony strip**. The resident is
suspended in the void, centred at or above eye height; its floor claim is
**zero cells**.

```
 ┌──────────────────────────────────┐
 │ balcony (3 rows, walkable)       │   rail at 1.1 m (em_detail owns it)
 │ ▓▓▓▓▓▓▓▓║                        │
 │         ║      BODY              │   void: no floor, all cells sealed
 │         ║    (suspended)         │   body centre_y >= rail + 0.5
 └──────────────────────────────────┘
```

Solves the one thing a courtyard cannot: a body that has volume but no
legitimate floor claim. `physical_overlap` (107 refusals) cannot fire on a
resident that owns no floor.

## OWNERSHIP — one fact, one authority (§7's five questions answered)

| fact | owner | why there |
|---|---|---|
| venue class (`courtyard` / `aerial`) | `spatial_contract.py`, **derived**: `containment == "precinct"` + posture `float` → aerial, else courtyard. Overridable via `placement_contract.venue`, exactly as containment already is | it already owns containment and support normalisation; this is one more derivation with provenance, not a declaration |
| court tier + dims | `spatial_negotiation.py`, from the body + clearance **masks it already computes**; emitted on the placement row | the negotiator owns placement decisions; a court is a placement whose room is made to measure |
| the plan row | `em_plan` v2 rows — **no new fields**: `venue` gains two values (it already carries `interior` / `porch` / `outside`), plus `court_w` / `court_d` on courtyard rows | extending a vocabulary is additive; a new schema is a fork |
| court/void architecture (parapet, ground, portal, balcony, rail) | `endless_museum.gd` builds the joint; heights come from `em_detail`'s constants | the assembler owns segment chaining and already advances z by variable depth; em_detail owns every built height (spike 07a) |
| walkable vs sealed cells | `_seal_cells`, unchanged | it already owns sealing; apron ring walkable, body sealed, void sealed |

1. *Which layer owns this today?* None — `outside` is a venue value with no
   architecture. 2. *Why can't it represent this?* No joint exists between
   segments; the tile grammar has no unroofed cell. 3. *What is the new
   concept?* Two venue **values** and one assembler **joint builder** —
   provider and assembler, no new canonical representation. 4. *What does it
   supersede?* The `outside`/`porch` dumping for precinct bodies (254 + 86
   placements today); those stay as fallback. 5. *Migration?* None — venue is
   computed per run; no stored data changes meaning.

## THE TAIL — said plainly, not designed away

**37 bodies (19%) exceed 34 m and fit neither venue.** Seven name themselves
caves/landscapes (`mc_cave` is 300 × 300 × 300 m). These are not exhibits, they
are *worlds* — the grid world already hosts them as maps. The honest corridor
treatment is a **threshold**: a portal that names them and leads out of the
museum, not a room that pretends to contain them. Out of scope here; it is a
third venue class and a separate ruling.

## NEGATIVE TESTS — each must fail today

| # | probe | today | after |
|---|---|---|---|
| 1 | `lab_room` 8.0 × 8.0 × 4.3, floor | refused / `outside`, "not hostable" | `venue=courtyard` COURT_S, stamped in a joint, apron walkable |
| 2 | `foucault_pendulum` 7.6 × 7.6 × 12.0 | precinct purely by height | stands in a COURT_S under open sky |
| 3 | `weather_vector_field`, posture `float` | refused or grounded | `venue=aerial`, floor claim 0 cells, balcony walkable, rail present |
| 4 | a plan with zero precinct rows | — | corridor builds **byte-identical**: no joints, no new nodes (the gate) |

## PROBE PLAN (next session, vertical spike per §4A)

One body through the whole pipe: `lab_room` → contract derives
`venue=courtyard` → negotiator emits court dims → plan row carries them →
assembler builds the joint → walker crosses segment N, the court, segment N+1
→ pathfinder green → capture published to /spatial-iterations. Then
`weather_vector_field` for aerial. Generalise only from what those two break.
