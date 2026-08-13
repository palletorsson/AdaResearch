# SPIKE 03 — where the fifteen go

*Research only. No repo file edited, nothing staged, no Godot booted. Every file
named below was checked against `HEAD`: `git diff HEAD --stat` over
`commons/scenes/endless_museum.gd`, `commons/scenes/em/`,
`tools/export_museum_plan.py`, `commons/data/template_patterns.json`,
`commons/data/spine_artifact_order.json` and `ada_run/em_plan.json` is **empty**,
so the working tree and HEAD are the same text for the whole target surface.*

## QUESTION

`HANDOVER.md` §7.3: `98 planned interior -> 18 "not in pool" -> 15 MORE VANISH
SILENTLY inside _stamp() -> 65 objects actually in rooms`. Nobody had established
where the fifteen go or why. Specifically: (a) every silent-skip path between
"the plan says place X here" and "X is a node in the scene tree"; (b) which log
and which do not; (c) whether 18 and 15 are one mechanism counted twice;
(d) capacity or defect; (e) the smallest change that makes each loss counted.

## PROBE

The four buildings the handover's chain was measured on, and their committed
capture logs:

| building | chapter | log |
|---|---|---|
| sainsbury-false-perspective-enfilade | primitives | `ada_run/spine_run/capture/sainsbury-false-perspective-enfilade.log` |
| louisiana-pavilion-chain | wavefunctions | `…/louisiana-pavilion-chain.log` |
| teshima-droplet | qfeplaboratory | `…/teshima-droplet.log` |
| grande-galerie-axial | symmetry | `…/grande-galerie-axial.log` |

Plus `ada_run/em_plan.json` (mtime 2026-08-13 15:25, the logs 15:29–15:30, so the
plan pre-dates the captures and is the one they consumed), and an offline
re-implementation of the whole stamp path in
`scratchpad/sim_stamp.py`, ported line for line from
`endless_museum.gd` so the chain can be re-derived without booting the engine.

## PIPELINE TRACE

```
em_plan.json  rows[]                                     tools/export_museum_plan.py:133
   -> _load_plan()                                       endless_museum.gd:1341
   -> _build_segment()  builds slots and _walk_cells     endless_museum.gd:1051
        tile row y  ->  segment z = y + VESTIBULE_H      endless_museum.gd:1136
   -> _deal_segment()   THE GATE                         endless_museum.gd:1430
   -> _deal_from_plan() row loop                         endless_museum.gd:1367
   -> _stamp()          instantiate / plinth / seal      endless_museum.gd:1851
   -> _seal_cells()     corridor guard                   endless_museum.gd:2149
```

## BASELINE

One print per museum (`endless_museum.gd:1414`), carrying `placed`, `exterior`,
`off_tile` and `missing`. No term for a `_stamp()` that returned `false`.
`_stamp` has six exit paths and exactly one of them prints.

## PREDICTION WRITTEN FIRST

Written before the simulation was run, and three of five were wrong, which is the
useful part:

1. **The 15 are `_seal_cells` corridor refusals.** — CORRECT.
2. **Some are `ps.instantiate() as Node3D` returning null** on a scene whose root
   is not a `Node3D`. — **WRONG. Zero of 98.** Every root in the four plans is a
   `Node3D` descendant (`MeshInstance3D`, `StaticBody3D`, `RigidBody3D`), and `as`
   accepts subclasses. The path is real and unlogged; it did not fire here.
3. **`_reaches_all`'s 400-cell bound produces false refusals in a 507-cell
   building** like Louisiana. — **WRONG.** It is fail-**open**:
   `endless_museum.gd:2263` returns `true` when the flood outruns the limit. A
   refusal is therefore always a genuine local pinch, never a budget artefact.
4. **18 and 15 are different mechanisms.** — CORRECT, and *understated*: the 18
   is itself two mechanisms, and the larger half is a defect (F2).
5. I did **not** predict F1. It was found by reading `_build_segment`, not by
   looking for it, and it is the finding that matters.

## FAILURES

### F1 — the plan path and the segment path hold `cell.y` in two different frames, 4 cells apart

EXPECTED: an artifact the negotiator put at tile row 2 stands at tile row 2.

ACTUAL: it stands 4 m closer to the entrance than the plan says, and 30 of the
corpus's 281 planned interior rows land **outside the building**, in the
vestibule.

CAUSE. `_build_segment` maps a tile row to a segment z by adding the lobby depth:

- `endless_museum.gd:87` — `const VESTIBULE_H := 4`
- `endless_museum.gd:1136` — `var z := y + VESTIBULE_H`
- `endless_museum.gd:1152` — `slots.append({"x": x, "y": z, "top": 0.0, "rank": 2})`

so every slot the dealer ever sees carries `y` in **segment** space.
`_deal_from_plan` builds its cell from the raw tile row:

- `endless_museum.gd:1400` — `var tz := int(tc[1])`
- `endless_museum.gd:1401` — `if … tz >= tile.size() …` — read as a **TILE** row
- `endless_museum.gd:1408` — `"x": tx, "y": tz, "rank": 2,` — stored as a **SEGMENT** z

One variable, two frames, in adjacent lines. `_stamp` then uses it as segment-local
(`:1903` `node.position = Vector3(x + 0.5, top, y + 0.5)`) and `_occupied_cells`
uses it as segment-local (`:2195` `var cz: int = zbase + int(cell.get("y", 0))`).
Nothing in between can notice, because both readings are plausible small integers.

The exporter is not at fault and its comment says so precisely —
`tools/export_museum_plan.py:133`, *"TILE coordinates — what endless_museum.gd
indexes its own tile by. The apron offset is arithmetic only this side knows, so
it is applied HERE. Handing the museum a plan-space cell plus an apron constant
would put the same number in two places, which is how every unit bug in this pass
started."* The apron was correctly collapsed on the Python side. The **vestibule**
was never collapsed on either side. `tools/em_white_cube_measure.py:165` and
`tools/em_module_measure.py:42` both do `z = y + VESTIBULE_H`; the one consumer
that actually places objects does not.

This is `HANDOVER.md` §8's endemic bug — *"two places holding one number"* — in a
new field, and the 1 m grid hides it the same way it hid `footprint` and
`front_clearance_m`: 4 and 4 are indistinguishable by value.

### F2 — two thirds of "not in pool" is the museum reading the wrong dictionary

EXPECTED: `N not in pool` means the plan named an artifact that cannot be built —
`order_to_walk.md` §2's dead artifacts arriving at the last stage.

ACTUAL: of the 18, **12 are alive in `_live`** — `map_ready`, scene on disk,
loadable right now. They are absent only from `commons/data/spine_artifact_order.json`.
Corpus-wide the figure is **46 of 69**.

```
ALIVE in _live, absent from the spine order (12):
  BigPipe, bunsen_burner, crystal, cube, f_order_bench, interactive_point_origin,
  mirror, paradox_stalker, point, snap_tetrahedron_puzzle   (+2 repeats across museums)
genuinely not buildable — no map_ready key or scene gone (6):
  mill_alhambra_p6m, snap_cube_puzzle, snap_tetra_puzzle, tt
```

CAUSE. `endless_museum.gd:1378-1380` builds `scene_of` from **`_pool`**:

```gdscript
var scene_of: Dictionary = {}
for e in _pool:
    scene_of[String((e as Dictionary).get("lookup", ""))] = String((e as Dictionary).get("scene", ""))
```

`_pool` is a **dealing order** — `_load_spine_pool` (`:723`) keeps only tokens
present in the spine-order manifest, 756 of 799 in this run. `_live` (`:665`) is
the museum's list of **what can be built**, and both other consumers in the same
file use it: the relatives path (`:1635` `var lv: Variant = _live.get(tok, null)`)
and the guest path (`:1707` `_live.get(gtok, null)`). Only the plan path resolves
scenes out of the order. So a token the negotiator chose is refused for not being
in a *queue* it was never going to be dealt from.

The comment at `:1377` states the wrong law: *"A plan naming an artifact the pool
does not carry is a stale plan"*. The plan is not stale; the lookup table is.

### F3 — the corridor guard is silent, and it is the whole of the fifteen

EXPECTED: a row that reaches `_stamp` and does not become a node leaves a line.

ACTUAL: nothing. `_stamp` returns `false` from six places
(`endless_museum.gd:1855, 1858, 1861, 1867, 1933, 1952`) and only one — the
`span_cap` refusal at `:1924` — prints. `_deal_from_plan` does not count the
`false` return at all: `:1411` `if _stamp(...): placed += 1` has no `else`.

Which of the six fires in the plan path can be settled by elimination, without
the engine:

| `_stamp` exit | line | logs? | reachable from `_deal_from_plan`? |
|---|---|---|---|
| `scene_path == "" or cell.is_empty()` | 1855 | no | **no** — `:1393` already refused `""`, and the cell is built literally at `:1407` |
| `load(...) as PackedScene == null` | 1858 | no (Godot prints its own ERROR) | **no** — every pool scene passed `ResourceLoader.exists` at `:657` |
| `instantiate() as Node3D == null` | 1861 | no | reachable, **fired 0 times** — all 98 roots are Node3D descendants |
| axis refused + `drop_if_unvaried` | 1867 | no | **no** — the plan path passes `{}` and `false` (`:1411`) |
| `span_cap` exceeded | 1933 | **yes** | **no** — plan path leaves `span_cap` at its `0.0` default |
| **`_seal_cells` returned false** | 1952 | **no** | **yes — the only one left** |

So the fifteen are corridor refusals, by elimination and not by inference. The
offline port confirms it numerically: with the shipped arithmetic it reproduces
**three of the four buildings exactly** (sainsbury 20/20, teshima 17/17,
grande-galerie 7/7) and is 3 high on Louisiana (24 against 21) — in exactly the
direction the port's one approximation predicts, since
`artifact_measurements.json` counts `MeshInstance3D` only while `_extent_of`
(`:2220`) also merges `CollisionShape3D`, so simulated bodies are too small and
seal too little. Re-run with `+VESTIBULE_H` restored, the same port matches only
one of four (19, 29, 13, 7). **The reproduction is itself the proof that F1 is
live in the shipped build** and not compensated somewhere downstream.

### F4 — the plan's rotation is discarded without a word

`em_plan.json` carries `rotation` on every row (`export_museum_plan.py:135`).
`_stamp` never touches `node.rotation` — the only rotation writes in
`endless_museum.gd` are the banner (`:1220`), the player/camera, and a prop
(`:2410`). `mode` and `wall` are dropped the same way. `CURRENT_STATE.md` gap 2
says this ("`_stamp` carries position only"); it is repeated here because it is a
loss with the same shape as the other three — the plan says something, the museum
does not do it, and no line records the difference. **65 of 65 stamped objects
lost their rotation**, which is a 100% loss channel sitting under a 66% one.

### F5 — the plan path's plinth count is hardcoded to zero

`_deal_from_plan` returns `"plinths": 0` (`:1419`) and never resets `_seg_plinths`,
because the reset at `:1441` lives after the early return at `:1433`. `_stamp`
does build plinths on this path (`:1898-1902`). Louisiana printed `+ 0 plinths`;
the number is not measured, it is asserted. Small, and the same family of fault.

## EVIDENCE

**The four numbers are right.** Re-derived from `ada_run/em_plan.json` and the
four committed logs, with no appeal to the handover:

| building | plan interior | log `not in pool` | log `stamped` | unaccounted |
|---|--:|--:|--:|--:|
| sainsbury-false-perspective-enfilade | 26 | 6 | 20 | 0 |
| louisiana-pavilion-chain | 38 | 3 | 21 | **14** |
| teshima-droplet | 24 | 6 | 17 | **1** |
| grande-galerie-axial | 10 | 3 | 7 | 0 |
| **total** | **98** | **18** | **65** | **15** |

- Interior counts come straight out of `em_plan.json` (26/38/24/10 = 98).
- The `18` reproduces exactly offline: rebuilding `live` from the 108 registry
  files and intersecting with `spine_artifact_order.json` yields
  `756 of 799 alive (43 not map_ready/on disk)` — byte-identical to
  `louisiana-pavilion-chain.log:223` — and the per-museum not-in-pool sets are
  6/3/6/3.
- The conservation closes per building: `rows == exterior + missing + placed +
  unaccounted`. Sainsbury 80 = 54+6+20+0. Grande Galerie 13 = 3+3+7+0. Teshima
  36 = 12+6+17+**1**. Louisiana 72 = 34+3+21+**14**.
- **No `off-tile` term appears in any of the four log lines**, and the clause at
  `:1416` only prints when `off_tile > 0`, so off-tile is zero on all four. Every
  interior row in all four plans has a 2-element `tile_cell` and there are no
  duplicate cells, so the `tc.size() < 2` skip at `:1397` also fired zero times.
  The 15 are not those.

**Corpus-wide, all 17 planned museums** (offline port, seal figures are a floor):

```
interior planned              281
not in pool                    69   (24.6%) — of which 46 are ALIVE in _live
seal-refused, silent          ~26   (floor; the port under-measures extents)
landing INSIDE THE VESTIBULE   30   — displaced clean out of the building by F1
stamped                      ~180   (64%)
```

**The handover's arithmetic closes and its diagnosis is right about the site and
incomplete about the cause.** "15 vanish inside `_stamp()`" is true. What it does
not say is that the fifteen are a *symptom*: the corridor guard is doing its job,
on cells the plan path handed it in the wrong coordinate frame.

## ANSWERS

**(a) Every path between plan and node.** Four in `_deal_from_plan` — venue
(`:1388`), missing scene (`:1393`), short `tile_cell` (`:1397`), off-tile
(`:1401`) — and six in `_stamp` (`:1855, 1858, 1861, 1867, 1933, 1952`). Ten.

**(b) Which log.** Three of the four in `_deal_from_plan` are counted and printed
(`:1414`); the `tc.size() < 2` skip at `:1397` is silent and uncounted, and
`off_tile` is printed only when non-zero, so its absence is ambiguous between
"zero" and "not reached". One of the six in `_stamp` prints (`:1924`). **Six of
ten losses are invisible; the one that actually fires is among them.**

**(c) Same mechanism, or two?** **Three, not two.** `not in pool` is a lookup
against `_pool` (`:1379`); the fifteen are `_seal_cells` (`:1952`); and inside
`not in pool` there are two different things again — 12 alive-but-unordered
(F2, a defect) and 6 genuinely unbuildable (correct). Nothing is counted twice.

**(d) Capacity or defect.** The corridor guard is **capacity**, and correctly so
— `:1943`, *"a museum with an unreachable room is worse than a museum with an
empty plinth"*. But its firing rate here is a **defect** symptom: it is refusing
bodies that were placed 4 m from where the negotiator put them, 30 of them inside
a 15 x 4 lobby. F2 is a plain defect. F1 is a plain defect. F4 and F5 are
reporting defects. **The only honest capacity refusal in the whole chain is the
`exterior` count, which is already printed.**

**(e) Smallest change that makes each loss counted.** Below.

## PROPOSED FIX — not applied

Four changes, each independent, in increasing size. None touches the grid system.

**1. Count the refusal (3 lines).** In `_deal_from_plan`, give `:1411` an `else`:

```gdscript
if _stamp(seg, scene, tok, cell, zbase, 1, {}, false):
    placed += 1
else:
    refused.append(tok)
```

and add `", %d refused by the corridor guard: %s"` to the print at `:1414`. This
is the doctrine's own rule — a fallback must announce itself — and it is what
turns the next three from inferences into readings. **Do this one first, alone.**

**2. Name the frame (1 line, gated).** `_deal_from_plan` should build the cell in
segment space:

```gdscript
"x": tx, "y": tz + VESTIBULE_H, "rank": 2,
```

leaving `:1401`'s bounds test on the raw `tz`, since that one is genuinely a tile
index. Additive and gated by construction: only the `--em-plan` path is touched
and every unplanned museum is untouched. Better still, and the version that stops
it recurring: have `_deal_from_plan` take the cell from the **slot list
`_build_segment` already computed** rather than re-deriving it, so there is one
producer of segment z instead of two.

**3. Resolve scenes from `_live`, not `_pool` (2 lines).** Replace the `for e in
_pool` loop at `:1378-1380` with a `_live.get(tok)` lookup, matching the
relatives path at `:1635` and the guest path at `:1707`, and keep the `missing`
count for tokens `_live` genuinely does not have. Expected effect: `not in pool`
18 -> 6 on the four, 69 -> 23 corpus-wide. **Predicted as a lower bound** — some
of the 12 will then reach `_stamp` and be refused by the corridor guard, which
change 1 will make visible instead of moving the loss one stage later.

**4. Carry the rotation (2 lines).** `node.rotation_degrees = Vector3(0,
float(row.get("rotation", 0.0)), 0)` before `add_child`, i.e. before `_seal_cells`
measures the extent, since rotating a non-square body changes its footprint. This
is the only one of the four that changes the picture of an already-passing museum,
so it wants its own before/after iteration.

## NEGATIVE TEST — must FAIL today, PASS after

**N1, the conservation law (pure Python, joins the 63-test suite as
`tools/test_em_plan_conservation.py`).** For each museum with a committed capture
log, parse the `[em-plan]` line and assert

```
len(rows) == exterior + missing + off_tile + placed + refused
```

against `ada_run/em_plan.json`. **Fails today on two of four**: Louisiana closes
at 58 of 72 (short by 14) and Teshima at 35 of 36 (short by 1), because the log
line has no `refused` term to parse. Passes after fix 1 and a re-capture. This is
the test that makes the loss *countable*; it does not care whether the loss is
right, only that it is stated.

**N2, the frame (headless GDScript, `commons/testing/test_plan_frame.gd`).** Boot
`endless_museum` with a one-row synthetic plan naming a known-good token at
`tile_cell [x, 0]`, for a template whose tile row 0 is floor, and assert

```gdscript
assert(is_equal_approx(node.position.z, 0.0 + VESTIBULE_H + 0.5))
```

Today it is `0.5`. **Fails by exactly `VESTIBULE_H` metres**, which is the number
the test exists to name. The stronger variant, and the one that would have caught
this the first time: assert that the stamped node's cell is a member of the same
`slots` array `_build_segment` produced, so the two frames cannot diverge silently
again.

**N3, the lookup (pure Python).** Assert that every token in `em_plan.json` that
is `map_ready` with a scene on disk is resolvable by the same table the museum
uses. Today, expressed against `spine_artifact_order.json`, **46 of 281 fail**;
after fix 3 the assertion is against the registry and passes.

Each of the three fails today for a different reason, which is the point: the
three losses really are three.

## OPEN

1. **Has any `--em-plan` capture ever been shot from the right place?** F1 has
   been live since `_deal_from_plan` was written, so every planned frame in
   `/spatial-iterations` shows objects 4 m nearer the entrance than the plan
   says. `_compose_auto_shot` picks its standpoint from `_shot_targets`, which
   `:1982-1988` fills from the same displaced cell — so the camera moved with
   them and the frames look composed. That is the most expensive property of this
   bug: it is invisible in the evidence.
2. **`_deal_from_plan` has no `used` set.** Two rows on one cell would both stamp
   and interpenetrate. Zero duplicates exist in today's plan, so it does not bite
   — but nothing asserts it, and the negotiator is not obliged to keep it true.
3. Whether the 12 alive-but-unordered tokens *should* be housed is a curriculum
   question, not an assembly one. Fix 3 makes them arrive; somebody has to want
   them there.

## FILES

Read: `commons/scenes/endless_museum.gd` (:87, :633-745, :1051-1173, :1341-1422,
:1851-1989, :2149-2273), `tools/export_museum_plan.py`,
`commons/data/template_patterns.json`, `commons/data/spine_artifact_order.json`,
`ada_run/em_plan.json`, `ada_run/artifact_measurements.json`,
`ada_run/spine_run/capture/*.log`, `doc/reports/spine_run.md` §5.

Written: `scratchpad/sim_stamp.py` (the offline port) and this file. **No repo
file was modified and nothing was staged.**
