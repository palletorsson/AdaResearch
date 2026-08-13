# Four more stages of the spatial pipeline, photographed before and after

2026-08-13. Seven stages already had a pair in `/spatial-iterations` — plan consumption,
plinths, rotation preference, route rule, wall emptying, wall colour, walk order. These are the
four that did not.

Renderer: `tools/pipeline_images.py` (new). Three of the four stages produce a PLAN, not a build,
so nothing about them ever reached Godot; the tool rasterises the stage's own return value with
PIL, using `tools/spatial_palette.py` so the diagram is coloured the same way every other spatial
diagnostic in the repo is. The fourth stage does reach the engine, and its pair is two real Godot
renders.

---

## The number I could be wrong about

**Written before reading any of the four tools** (`scratchpad/prediction.txt`, stamped
2026-08-13T07:32:27Z):

> Of the four stages I predict **2 of 4** have a REAL toggle allowing a true before/after.
> Reasoning: `--self-test` is by name a harness that constructs a fault, so it should image both
> sides; `hang_run` reads like a rule inside a larger negotiate pass, so likely no flag;
> `threshold` likewise; `precinct` is a classification derived from data, so probably no toggle
> at all.

**Measured: 2 of 4.** The count was right and half the reasoning was wrong.

| stage | real toggle? | what it is |
|---|---|---|
| threshold | **no** | `threshold()` is a library function. It is not reachable from any CLI, and `spatial_slice.threshold_diagnostic_svg` — the only thing that draws it — is defined *after* the `if __name__ == "__main__"` block, so it is dead to the command line. Before = the state the stage replaced. |
| hang_run | **yes** | `exhibition_brief.py --museum=<key>`. Both the floor answer and the wall answer are computed on every run; the flag decides which one is printed as THE answer. I predicted no flag here. |
| precinct | **no** | `containment` is derived from the measured body against `WIDEST_SLOT_M` / `CERTIFIED_WALL_M`. Before was produced by raising both to `1e9` at source. |
| correspondence gate | **yes** | `verify_placement.py --self-test`, which builds a corrupted twin, expects the gate to catch it, and exits non-zero if it stays quiet. |

---

## 1. The threshold — door, sightline, caption

Published: `http://localhost:3003/spatial-iterations` → `20260813-095925`

| | path | mtime (UTC) | bytes |
|---|---|---|---|
| before | `ada_encyclopedia/public/spatial-iterations/20260813-095925/1_before_no_door.png` | 2026-08-13T07:59:04.623Z | 51,209 |
| after | `ada_encyclopedia/public/spatial-iterations/20260813-095925/2_after_door_sightline_caption.png` | 2026-08-13T07:59:04.781Z | 67,144 |

Source frames: `ada_run/pipeline_images/threshold/`.

**Caption.** `capuchin-crypt-corridor`, `lab_room` — 8.04 × 7.98 × 4.30 m, a precinct, standing on
porch ground. BEFORE: 70 cells in this building have floor on both sides, so any of them could be
a door; none is. The line from the standing point `[18, 23]` to the work is 14 cells long and
meets 1 solid wall cell, at `[18, 20]`. AFTER: north wall at `[18, 20]`, certified 4 m portal —
one of the three widths `PORTAL_WIDTHS` allows; 14-cell sightline crossing the wall only at the
door; caption plate 0.62 × 0.42 m at 1.55 m, `rect_uv [2.35, 1.34, 2.97, 1.76]`. Of the 40
nearest candidate doors, **39 are fire exits** — a hole with no line to the work. This museum is
the corpus's most extreme case; the stage took candidate #0 anyway, because it sorts by distance
and the nearest door here happens to be the only one that works.

**A fault the drawing found.** The picture would not compose. Drawing the door and the sightline
in the same frame for the first draft (`kanazawa-vista-v2`) put them six cells apart, which is
not what the accepting trace says. `threshold()` proves that the line from the standing point to
the work *crosses the wall only at the door*, implemented as

```python
blocked = [c for c in line if plan.in_bounds(*c) and plan.grid[c[1]][c[0]] == "4" and c != cell]
if blocked:
    continue
```

— so a line that crosses **no wall at all** also passes, and the certified portal is then a door
somewhere else in the building. Measured over every museum in `slot_capacity.json`, placing
`lab_room` and asking for a threshold: 30 museums, 28 ACCEPT, and in **22 of the 28 the door is
not on the sightline**. Only 6 (`capuchin-crypt-corridor`, `libeskind-void-axis`,
`louisiana-pavilion-chain`, `sando-threshold-run`, `teshima-droplet`,
`thoronet-circumambulation-void`) put the door in the way of the look. 2 REJECT outright
(`chichu-buried-cells`, `katsura-miegakure-circuit`: no door sees the work).

The cause is upstream: the standing point is derived as three cells back from the door's inside
face, but the precinct itself is placed in the porch — *outside* the walls — so on most plans the
"visitor standing inside" is already standing next to the work with nothing between them. The
after frame uses `capuchin-crypt-corridor` precisely because it is one of the six where the claim
is real, and the caption says so on the frame. **Not fixed** — this is a report, and the fix is a
one-line assertion (`door_cell in line`) that would turn 22 accepts into rejects and needs a
decision about the standing point first.

---

## 2. Lineage runs hung on wall runs

Published: `20260813-095949`

| | path | mtime (UTC) | bytes |
|---|---|---|---|
| before | `.../20260813-095949/1_before_floor_series.png` | 2026-08-13T07:59:05.040Z | 69,453 |
| after | `.../20260813-095949/2_after_wall_runs.png` | 2026-08-13T07:59:05.221Z | 89,927 |

**Caption.** `uffizi-spine-enfilade`, 11 DNA runs taken from the first 14 spine anchors that carry
relations. **Routed to WALLS 8/11; the same runs on the FLOOR 1/11.** The floor answer starves
because this museum offers 1 slot series — 36 exist across all 30 museums, and 18 of 30 offer
none, against 481 anchors that declare a run. 8 of the museum's 27 walls carry a lineage. The
widest row is 5 works of 3.53 m centred on a 30 m wall (`west_28_14`), drawn in elevation in the
after frame with the declared feature band outlined.

The 3 runs not on a wall are not failures of the wall rule, and the frame says which is which:
2 are precinct works handed on to the threshold (`folding_past`, `lab_room`), and 1 is a genuine
reject — `floating_sphere_field`, a 4.00 m body that does not fit a 4 m wall.

**The brief I was given said 11/11 vs 1/11. It does not reproduce.** Measured today the best
figure in the corpus is 8/11, and no museum reaches 11/11: `dia-beacon-field` 8/11 (floor 0/11),
`pompidou-plateau-libre` 8/11 (floor 0/11), `labrouste-stack-hall` 8/11 (floor 6/11),
`soane-cabinet-vista` 7/11 (floor 7/11), `neue-nationalgalerie-free-plan` 2/11. Since 2 of the 3
misses are precincts routed elsewhere by design, 8 of 9 *hangable* runs find a wall — which may
be where the 11/11 came from, but I could not find it written anywhere, so the frame carries the
measured number.

---

## 3. Precinct artifacts — entered, not viewed

Published: `20260813-095957`

| | path | mtime (UTC) | bytes |
|---|---|---|---|
| before | `.../20260813-095957/1_before_exhibited.png` | 2026-08-13T07:59:05.841Z | 65,549 |
| after | `.../20260813-095957/2_after_ground.png` | 2026-08-13T07:59:06.014Z | 78,143 |

**Caption.** **535 of 2707 artifacts (19.76%)** measure beyond the 8 m widest slot or the 4 m
certified wall, so they are precincts (`ada_run/spatial_slice/precinct_census.json`, computed by
running `staged_contract` over every dressing room). The source comment in `spatial_contract.py`
says 536 of 2485 (22%); the count is stable, the denominator has grown.

`lab_room` (8.04 × 7.98 × 4.30 m) in `uffizi-spine-enfilade`. As an exhibit it ranks all 20 slots,
tries every rotation and mode, and fails at **step 7** — `body is 4.30 m tall on a 0 m support,
the room is 4 m` — with the museum authored, so step 6 (widen the building) is skipped. As a
precinct the first trace is `containment` and it stands on porch ground: **ACCEPT**, score 0.59,
`required_support` overridden from the registry's `'table'` to `'floor'`, room unchanged (0
expansions).

Because there is no CLI toggle, BEFORE is the negotiator with `WIDEST_SLOT_M` and
`CERTIFIED_WALL_M` raised to `1e9` at source. That is the right lever rather than setting
`containment` on the dataclass: the constants also govern `required_support`, and it is the
registry's `'table'` — meaningless for an 8 m laboratory — that does the actual refusing.

**A/B over 40 randomly sampled precinct artifacts** (seed 7, same museum,
`ada_run/spatial_slice/precinct_ab.json`): **14/40 placed without the rule, 20/40 with it — 6
rescued, and 26 reported in a different venue.** So the category is not mostly an accept/reject
switch; on 34 of 40 it changes the *diagnosis* (a REJECT reported against interior slot `6,2`
becomes a REJECT reported against `outside`) and the search path, and on 6 it is the difference
between a work having somewhere to stand and not.

An earlier version of this measurement set `c.containment` on the dataclass and left
`required_support` alone; it reported 0/40 result changes and 20/40 both ways. That number is
wrong and is recorded here only because it looked publishable — the precinct branch had already
rewritten `required_support` to `'floor'` when the contract was built, so the "before" arm was
carrying half the fix.

---

## 4. The correspondence gate catching a real fault

Published: `20260813-100006`

| | path | mtime (UTC) | bytes |
|---|---|---|---|
| before | `.../20260813-100006/1_before_approved.png` | 2026-08-13T07:59:06.656Z | 1,366,221 |
| after | `.../20260813-100006/2_after_corrupted_caught.png` | 2026-08-13T07:59:06.904Z | 1,375,340 |

Underlying Godot renders (`--xr-mode off --no-window`, each under `godot_watchdog.py`, serialized,
`iso` angle, 1800 × 1200):

| render | path | mtime (UTC) | bytes |
|---|---|---|---|
| approved | `%APPDATA%/Godot/app_userdata/Ada Research Zero One/gate_shots/Museum_Spatial_Slice/iso.png` | 2026-08-13T07:55:15.143Z | 1,718,035 |
| corrupted twin | `.../gate_shots/Museum_Spatial_Slice_Corrupt/iso.png` | 2026-08-13T07:55:45.637Z | 1,728,168 |
| control (same map, second run) | `.../gate_control/Museum_Spatial_Slice/iso.png` | 2026-08-13T07:57:22.684Z | 1,718,111 |

**Caption.** BEFORE: `Museum_Spatial_Slice` as approved — 2 planned, 0 failed, PASS at tolerance 0
cells; `science_screen` measured at centre `[5.0, 1.92]` m, base 0.727 m, occupying 5 cells.
AFTER: the twin `--self-test` builds by moving one token three cells while leaving the approved
plan in the map metadata untouched — 2 planned, **1 failed**, FAIL, `science_screen: body centre
sits 3.50 m from where it was planned`, centre `[5.0, 1.92]` m → `[8.0, 1.92]` m. Run fresh at
09:56 local: `RESULT: clean map PASS; corrupted map CAUGHT`, and the twin was removed afterwards
(verified: `commons/maps/Museum_Spatial_Slice_Corrupt` does not exist).

**A control run, and why the gate cannot be a picture.** I captured `Museum_Spatial_Slice` a
second time with nothing changed, to measure the noise floor. Fraction of frame differing by more
than 8 grey levels:

| angle | control (same map, two runs) | fault (3.50 m move) | ratio |
|---|---|---|---|
| iso | 1.020% | 2.556% | 2.50x |
| iso_perfect | 0.165% | 0.547% | 3.32x |
| front | 0.415% | 1.804% | 4.35x |
| top | 0.824% | 2.028% | 2.46x |
| left | 0.244% | 2.012% | 8.26x |

The biome reseeds between runs — trees, particles and ground scatter are different objects in
every capture — so a full percent of the isometric frame changes when nothing has changed at all.
A 3.50 m misplacement is 2.5x that. The fault happens to be visible by eye in these two frames
(the screen detaches from its wall recess and floats), but the numbers say a pixel diff would not
have been able to prove it. That is the argument for a gate that measures the body centre in
metres and names the number, which is what this one does.

---

## Gaps — stages or claims I could not image honestly

- **The threshold has no true before.** There is no flag, and `threshold()` has no consumer
  anywhere in the repo — nothing writes a door into a map, and the one function that draws it is
  unreachable from a CLI. The "before" frame is therefore the state the stage replaced (a precinct
  on ground with a solid wall), drawn from the same plan and the same standing point, not the
  output of a disabled stage. It is labelled as that on the frame.
- **The precinct pair is one artifact, not the corpus.** The corpus claim is the census (535/2707,
  a pure body measurement) plus a 40-artifact A/B. A full 535-artifact A/B was attempted and
  abandoned: the first sample of 60 ran past a 600 s budget (some precincts are 300 m across and
  send the ladder into a very long search), so it is a sample, and the sample size is on the frame.
- **`11/11` for the wall runs is unreproducible.** Not imaged, because I could not make it true.
  The frames carry 8/11 vs 1/11 measured today, and the discrepancy is written above rather than
  quietly rounded into agreement.
- **The gate pair is `iso` only.** All five angles were captured and measured (table above), but
  only one is published per side, chosen because the fault is legible in it. The other four are
  still in the Godot user dir if the choice needs auditing.
- **No stage was fixed.** The door-not-on-the-sightline fault is reported, not repaired.

## Files

- `tools/pipeline_images.py` — the renderer, `--stage=threshold|hang_run|precinct|gate|all`
- `ada_run/pipeline_images/` — the eight frames plus `facts.json`
- `ada_run/spatial_slice/precinct_census.json` — 535 precincts of 2707, with bodies
- `ada_run/spatial_slice/precinct_ab.json` — the 40-artifact A/B, both arms per token
