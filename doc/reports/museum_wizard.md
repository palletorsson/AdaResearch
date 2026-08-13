# The Museum Wizard

> Written 2026-08-13. Section 3 (the prediction) was written BEFORE a line of the
> new wizard existed, and is not edited afterwards — only answered, in §6.

---

## 1. What `/map-wizard` actually is

### 1.1 The step list, quoted from source

The brief (and `MEMORY.md`) call it "the 8-step wizard". **It has thirteen steps.**
Quoted verbatim from `ada_encyclopedia/src/app/map-wizard/page.tsx:49-63`:

```tsx
const STEPS = [
  { op: "order", n: "1", title: "Order", sub: "the cast as a 1D strip" },
  { op: "typology", n: "2.5", title: "Typology", sub: "template first — three frames" },
  { op: "room", n: "3", title: "Rooms", sub: "grown around each artifact" },
  { op: "walls", n: "4", title: "Walls + dressing", sub: "segments, doors, hangar system" },
  { op: "doors", n: "4.3", title: "Doors", sub: "frames + naming signs" },
  { op: "templates_fixed", n: "5", title: "Set pieces", sub: "the quarantine yard" },
  { op: "elevation", n: "6", title: "Elevation", sub: "section along the walk" },
  { op: "spans", n: "6.5", title: "Spans", sub: "bridges over carved chasms" },
  { op: "paths", n: "7", title: "Paths", sub: "connective tissue, cared for" },
  { op: "arrival", n: "8", title: "Arrival", sub: "the entry as story" },
  { op: "wall_hangar", n: "9", title: "Principal wall", sub: "hangar wall + props + kin" },
  { op: "landmark", n: "9.5", title: "Landmark + light", sub: "tower + lit path" },
  { op: "final", n: "✓", title: "Review + save", sub: "metrics · pathfinder · recipe" },
];
```

The fractional numbers are the tell: `2.5`, `4.3`, `6.5`, `9.5` are ops inserted into a
canon that was once numbered 1..9. The rail is an accreted list, not a designed eight.
Anyone budgeting "eight steps" from memory is budgeting for a page that no longer exists.

### 1.2 The shape underneath the steps

From the page's own header comment (`page.tsx:3-12`):

> "Each step of the composition canon (commons/data/composition_grammar.json) gets its own
> options AND its own abstraction: the artifact order is a 1D strip, typology is three
> frames, rooms are a growing plan, walls add the hangar dressing, elevation is a SECTION
> along the walk, paths close the tissue."

Four invariants make the wizard work, and they are the transferable part:

1. **One engine call, all stages at once.** `compose()` POSTs the whole `spec` to
   `/api/map-wizard` on every change; the engine returns `stages[]`, an array of
   `{op, ...}` records. The rail does not re-run anything — `st(op)` is a lookup
   (`page.tsx:211`). So every step always shows live state, even the ones behind you.
2. **Each step gets its own ABSTRACTION, not a generic viewer.** Order is a bar strip
   sized by measured footprint; typology is three thumbnail plans; elevation is a section;
   paths is a plan. The step's drawing IS the argument for that step.
3. **Recipes are memory.** `commons/data/wizard_recipes/*.json`.
4. **A live 3D escape hatch.** `sendToGodot()` renames the composition to `MapSim_Live`
   and POSTs to `/api/map-simulator/control`, with a 3-second heartbeat dot.

### 1.3 What a recipe contains

`commons/data/wizard_recipes/Thread_Gate.json` — the promoted standing gate:

| field | content |
|---|---|
| `name`, `date` | `Thread_Gate`, `2026-07-27` |
| `spec` | the full wizard input: `cast[7]`, `hero`, `anti`, `order.strategy`, `typology`, `grower`, `walls.dressing`, `yard`, `elevation`, `arrival{threshold,prologue,overview}`, `dwell{}`, `canon_date` |
| `score_soft` | `0.8` |
| `metrics` | 8 named scores (`room_band`, `enclosure`, `hall`, `arrival`, `elevation`, `compact`, `tissue`, `story`) |
| `pathfinder` | `{ok: true, reach: 0.9}` |
| `note` | why it was promoted, by whom, on what date |
| `regeneration_warning` | *"This recipe no longer reproduces the map on disk BIT-FOR-BIT … a recipe is not a time capsule unless new ops are gated off by default."* |
| `furnished` | the op-10 occupant pass that came after, and what it did not touch |

A recipe is therefore three things at once: an input you can replay, a receipt of what the
numbers were, and a note about how the replay lies.

---

## 2. Upgrade or sibling — the five answers

**Decision: SIBLING.** `/museum-wizard`, engine `tools/museum_wizard.py`.

**1. Which existing layer owns this?**
`tools/wizard_compose.py` (2120 lines) behind `/map-wizard` owns *"compose a walkable space
from a cast of artifacts, show every intermediate product, save the run as a recipe."* That
is the same sentence the museum chain needs. The ownership claim is real, not nominal:
`wizard_compose.py` already reads measured footprints, already enforces REACH, already
grows rooms, walls, doors, spans and a principal wall.

**2. Why can it not represent museums?** Four reasons, each structural, none a missing feature:

- **Its unit of placement is a cell in a room it invented.** A museum's unit is a `Slot` in
  a tile somebody authored, carrying `capacity.per_rotation`, `support`, `wall_sides` and a
  `venue`. `spatial_floorplan.from_museum()` sets `expandable=False` and says why: *"their
  proportions are the authorship, and widening the Uffizi to fit an artifact is not a
  placement decision, it is vandalism."* The map wizard's entire middle — `room`, `walls`,
  `elevation`, `spans`, `landmark` — exists to change the building. A museum forbids it.
- **Its output is `map_data.json`, three grid layers.** The museum's output is
  `ada_run/em_plan.json`, whose rows are `{token, cell, tile_cell, rotation, mode, venue,
  support_height_m, slot, wall}`. `tile_cell` and `venue` have no cell in a 3-layer grid;
  `mode` and `support_height_m` have no token in the interactables layer.
- **It has no wall as a placement domain.** `walls.dressing` puts a decorative
  `cluster:<name>:<rot>` on a room's back wall. `WallSurface` is a (u, v) metre domain with
  openings, occupancy, a declared feature band, and a front-clearance test against the
  floor. `hang_run` puts a DNA lineage on it as a spaced row. There is no data path from one
  to the other.
- **Its spec cannot say which museum.** The `Spec` type is
  `{cast, hero, anti, order, typology, grower, walls, yard, elevation, trim_approach,
  arrival, track}`. Adding `museum` would make ten of thirteen fields inert whenever it is
  set — a mode flag that silently disables most of the page, which is the shape of the
  failure `doc/SPATIAL_PIPELINE.md` §0 is written against.

**3. What does the new thing supersede?** Not `/map-wizard` — nothing there is retired. It
supersedes **the six-terminal-command habit**: `exhibition_brief.py` → `emit_dressing_room.py`
→ `spatial_floorplan.py` → `spatial_negotiation.py` → `export_museum_plan.py` → Godot →
`publish_iteration.py`, each printing to a console nobody kept, writing intermediate files
(`ada_run/em_plan.json`) nobody looked at between runs. It also supersedes `export_museum_plan.py`'s
implicit cast: that tool offers `spine_order()[:limit]`, a flat prefix. The wizard's cast comes
from the brief — features **plus their typed relations** — and that is a measured improvement,
not a preference: on `uffizi-spine-enfilade` the plain prefix placed **8, 7 interior**; the
brief-derived cast placed **15, 13 interior** into the same building.

**4. Why not upgrade anyway, given the shape is so close?** Because the shape is the
transferable part and the engine is not. The sibling reuses all four invariants
(§1.2) and shares nothing else. Two engines behind one rail would mean thirteen steps of
which ten are dead in one mode, and a `Spec` union nobody can validate.

**5. What is foreclosed by the split?** Honest cost: there are now two places to fix a
shared idea. If "recipes are memory" gets a `canon_pin` field, it must be added twice —
`commons/data/wizard_recipes/` and `commons/data/museum_recipes/` are separate stores with
separate schemas. That is a real duplication and the right moment to merge them is when a
third wizard appears, not before.

---

## 3. The prediction (written before building)

**Measure, fixed now so it cannot be bent later:** for each of the 13 rail steps, does the
museum chain (`brief → dressing room → floorplan → negotiation → plan export → assembly →
capture/publish`) contain a stage that performs *the same operation on the same kind of
object*, such that the step could be carried over with a data swap and no change to what
the step decides? Count the YESes.

**I predict 3 of 13.**

Reasoning, so the miss is diagnosable: I expect `order` (the brief is an ordering),
`doors` (`spatial_negotiation.threshold()` exists) and `final` (export + pathfind-analogue
+ save) to survive; and I expect the ten middle steps to die because the wizard GROWS its
building while the museum chain RECEIVES one. `room`, `typology`, `spans`, `landmark`,
`templates_fixed` have no counterpart at all in a fixed authored tile.

---

## 4. What was built

| file | role |
|---|---|
| `tools/museum_wizard.py` | the engine — 8 stages, `--apply=<step>`, `--save`, `--options` |
| `ada_encyclopedia/src/app/museum-wizard/page.tsx` | the rail |
| `ada_encyclopedia/src/app/api/museum-wizard/route.ts` | GET options · POST compose/apply/save |
| `ada_encyclopedia/src/app/api/museum-wizard/image/route.ts` | serves before/after frames, confined to `ada_run/museum_wizard/**.png` |
| `commons/data/museum_recipes/Uffizi_Spine_First.json` | the first recipe |

**Nothing re-implements a stage.** Every stage calls the tool that owns it — `brief_for`,
`staged`, `from_museum`, `run`, `hang_run`, `plan_museum`, `endless_museum.gd`,
`publish_iteration.py` — and reports what came back. The only logic the engine adds is
(a) which brief entries become the floor cast, and (b) drawing. `tools/spatial_*.py`,
`commons/scenes/em/*` and `measure_artifacts.gd` were **not edited**.

### The eight steps and what each shows

| # | step | its own abstraction | changes the world |
|---|---|---|---|
| 1 | Brief | kinship stanzas: every entry with its edge KIND and that kind's spatial rule | no |
| 2 | Staging | one footing tile-grid per body, coloured authored / generated / no-file | **yes** — writes missing dressing rooms |
| 3 | Building | the museum in plan: grid, 20 slots, 27 wall surfaces, spawn/exit | no |
| 4 | Negotiation | plan + table; hover links row to body; every REJECT keeps its failing rule | no |
| 5 | Lineage | the one **elevation** in the wizard — a wall as a (u, v) domain in metres | no |
| 6 | Plan | before/after counts and the token diff against what is on disk | **yes** — rewrites one museum's entry in `em_plan.json` |
| 7 | Assembly | two headless Godot frames: dealer vs `--em-plan` | **yes** — 2 boots |
| 8 | Publish | frames ready, run metrics, recipe save | **yes** — writes an iteration + a recipe |

### The one decision the engine makes, and shows

Features and their typed relations go to the **floor**; `dna_variant` entries do **not**.
Five variants of one scene are one object five times, and would eat five slots. They are a
lineage, and step 5 routes a lineage to a wall. This is stated in the panel, not buried.

---

## 5. Proved end to end on `uffizi-spine-enfilade`

**URL: `http://localhost:3003/museum-wizard`** (each step deep-links, e.g.
`?step=negotiate`).

**Screenshots** — `doc/reports/museum_wizard/`:

| file | panel |
|---|---|
| `wizard_step1_brief.png` | step 1, 8 anchors → 16 bodies + 6 lineages |
| `wizard_building.png` | step 3 |
| `wizard_negotiate.png` | step 4 — the plan, the table, the compromises |
| `wizard_lineage.png` | step 5 — wall elevations |
| `wizard_export.png` | step 6 — the diff and the plan before/after |
| `wizard_assemble.png` | step 7 — the two Godot frames |
| `wizard_publish.png` | step 8 |

(Those page screenshots are on disk but **not in git** — `.gitignore:373` is
`doc/reports/**/*.png`, a standing project rule. The frames that matter are published,
below.)

The wizard's own before/after frames live in
`ada_run/museum_wizard/uffizi-spine-enfilade/` and were published as iteration
**`20260813-095228`**, now the top row of `http://localhost:3003/spatial-iterations`
(6 images; the page computed the deltas itself: placements +7, interior +6, rejected +1).

**Numbers from the run** (`commons/data/museum_recipes/Uffizi_Spine_First.json`):

```
cast 16 · placed 15 · rejected 1 · interior 13 (86.7%)
lineages 6 · walled 4 · rooms on disk 16 (all authored)
rejected: fractal_recursion_2 — support_matches_contract:
          slot offers 'podium', artifact needs 'platform'
```

Godot, both boots under `tools/godot_watchdog.py --grace=150 --stall=30`, one at a time,
`--xr-mode off --no-window`, never `--headless`:

```
before (dealer)    19.2 s  rc 0   shot composed at 2.5,12.5 — 4 of 31 dealt objects in view
after (--em-plan)  18.2 s  rc 0   shot composed at 1.5,13.5 — 4 of 16 dealt objects in view
```

### Three findings from proving it, each a number I could have been wrong about

**a. The plan HALVES the object count, and that is not automatically a win.** The blind
dealer stamps 31 objects (it fills every slot from the pool); the negotiated plan stamps
16 (the brief's cast). The after-frame is legibly a museum with works in it rather than a
room of empty vitrines — but "fewer objects" is what the numbers actually say, and anyone
reading the pair as "the negotiator added things" is reading it wrong.

**b. The camera moves when the plan moves, so the pair is not a controlled comparison.**
`endless_museum._compose_auto_shot()` chooses its standpoint by *what it can see of what
was dealt*. Change the deal and the eye relocates — here by one cell (2.5,12.5 → 1.5,13.5),
close enough to be fair, but not by construction. This is the DNA section's
"the camera is standing in the wrong place" trap wearing museum clothes. The wizard
therefore prints the engine's own standpoint line under each frame and warns about it in
the panel rather than presenting two pictures as if they were a controlled experiment.

**c. The non-console Godot exe writes nothing to stdout — the standpoint line is in the
log file, and the obvious way to find that file is wrong.** `project.godot` has
`file_logging/enable_file_logging=true`, and Godot rotates the previous run's log to
`debug_<stamp>.log` **at boot**, so that rotated file's mtime is newer than the run's start
and a plain newest-file search returns the PREVIOUS run's output. The first assembly pass
came back with a standpoint for the before-frame and silence for the after-frame, which
looks exactly like an engine that failed to compose. `godot.log` is always the run that
just finished; `_shot_log()` reads that first and only falls back to a scan.

### Things checked because they are the standing traps

- `--em-segments` is never passed without `--em-shot` (it is inert alone).
- One Godot at a time — the two boots are sequential `subprocess.run` calls.
- `em_plan.json` holds all 30 museums; the wizard rewrites **one key** and preserves the
  rest. Verified by diffing against a backup: `changed keys: ['uffizi-spine-enfilade']`.
- Step 2 never overwrites an authored dressing room — it writes only files that are absent.
  On this run that was 0 files, so the staging before/after frames are legitimately
  identical, and say so in their own captions.

---

## 6. The measured value

**Predicted 3. Measured 2.**

| # | map-wizard step | museum-chain counterpart | carries over unchanged? |
|---|---|---|---|
| 1 | order | `exhibition_brief` orders too — but the order is *taken* from `spine_artifact_order.json`, never chosen; there is no museum meaning for crescendo/narrative/rhythm/manual, and the panel had to be rebuilt as kinship stanzas | **no** |
| 2.5 | typology | `from_museum` — choose the frame before anything grows into it. Same decision, 30 tiles instead of 3 grown options; the clickable-plan panel carries straight over | **YES** |
| 3 | room | rooms are authored; a body gets a slot | no |
| 4 | walls + dressing | walls arrive with the building; `WallSurface` is a venue, not dressing | no |
| 4.3 | doors | `threshold()` is about the route to a placement, not door leaves; museum openings are authored into the tile | **no** (predicted yes) |
| 5 | set pieces | nothing | no |
| 6 | elevation | `support_height_m` varies per placement, but the floor is fixed — `expandable=False` | no |
| 6.5 | spans | nothing | no |
| 7 | paths | `_route_between` derives the route; nothing chooses it | no |
| 8 | arrival | spawn and exit are given by the tile's first and last rows | no |
| 9 | principal wall | `hang_run` is the closest analogue — pick a wall, lay a row, veto on front clearance — but the wizard *searches* for a wall it will build and dresses it with a cluster, and the panel had to become an elevation | no |
| 9.5 | landmark + light | nothing | no |
| ✓ | final | export + counts + save-as-recipe. Same operation, data swap only | **YES** |

**Where the prediction went wrong is more useful than the count.** I was one high, but I
was wrong about *which two of my three*: I predicted `order` and `doors` would survive and
they did not, and I predicted `typology` would die and it is the cleanest survivor. The
error has one cause. I ranked the steps by *how mechanical they sound* — ordering a list
and hanging a door feel portable, choosing a template feels bespoke. The actual predictor
is **who owns the building**: every step that CHANGES the building dies (`room`, `walls`,
`elevation`, `spans`, `paths`, `arrival`, `landmark`, `set pieces`, and `doors`, which cuts
holes in walls the wizard drew), and only the steps that stand OUTSIDE the building —
choosing which one, and reviewing what happened — survive. That rule would have got both
the number and the membership right, and it is the rule to use next time a wizard is
proposed for a stage of this pipeline.

`order` is the one marginal call: the brief genuinely orders artifacts, and if the test
were "same decision" rather than "same panel, data swap only" it would count and the
prediction would have been exactly right at 3. I am scoring it NO because in the museum
chain that step decides nothing — the order is read, not chosen — and a step that decides
nothing is not the same step.

---

## 7. Not committed

Everything above is left in the working tree for review. Files touched:

```
new     tools/museum_wizard.py
new     ada_encyclopedia/src/app/museum-wizard/page.tsx
new     ada_encyclopedia/src/app/api/museum-wizard/route.ts
new     ada_encyclopedia/src/app/api/museum-wizard/image/route.ts
new     commons/data/museum_recipes/Uffizi_Spine_First.json
new     doc/reports/museum_wizard.md + doc/reports/museum_wizard/*.png
new     ada_run/museum_wizard/uffizi-spine-enfilade/*.png
new     ada_encyclopedia/public/spatial-iterations/20260813-095228/ (+ index.json)
CHANGED ada_run/em_plan.json — the 'uffizi-spine-enfilade' entry only, 8 → 15 placements
```

`ada_run/em_plan.json` is tracked and was clean before this pass; a backup of the previous
version is in the session scratchpad. A concurrent session is writing `tools/spatial_*.py`,
so nothing here was staged or committed.
