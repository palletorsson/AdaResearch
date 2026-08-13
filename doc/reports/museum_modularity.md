# When are we going to shift the museum to become modular

> "when are we going to shift the museum to become modular"
> — and earlier: "consider the museum as modular and built. The museum tiles
> modules need to be lighter."

The honest answer has three parts, and only the third is work.

1. At the **plan** level the museum has been modular since it was written: it
   deals segments from 30 authored tiles in `commons/data/template_patterns.json`.
2. At the **kit** level a complete, certified module system already exists —
   `commons/data/museum_module_kit.json`, `MuseumWallPiece`, `MuseumWallRun`,
   `MuseumWallKitAtlas` — and the Endless Museum does not use one line of it.
   **It should not.** Measured, it is 11.7× heavier than what the museum builds
   today, which is the opposite of the brief.
3. At the **geometry** level the museum is not modular at all: it stamps one
   `BoxMesh(1, 3, 1)` per wall CELL. A 34 m enfilade wall is thirty-four
   anonymous cubes. That is the gap, that is where "lighter" lives, and it is
   fixed here — **6826 wall boxes → 936 across the corpus, 7.29× fewer, with the
   frame unchanged to within 8/255.**

No template tile was edited. §3 explains why the measurement forbids it.

---

## 0. THE PREDICTION, written before any measurement

`doc/reports/museum_modularity_prediction.txt`, mtime **2026-08-13 10:40:58**.
The first measuring tool, `tools/em_module_measure.py`, has mtime **10:42:07**.
The prediction is 69 seconds older than the instrument, and the definition it
measures was fixed in the same file.

> predicted % of museum wall cells that sit in runs of 4 m or longer: **52%**

**Measured: 55.1%** of all wall run (30 museums as built, 5071 m). Tile-only,
with the engine's vestibule and outer skin removed: 51.0%.

Right to within 3.1 points — and worth very little, because it was extrapolated
from a histogram already in `white_cube.md`. The four secondary predictions,
which were not extrapolations, are where the pass actually learned something:

| prediction | predicted | measured | |
|---|---|---|---|
| museums with ≥1 run of 4 m+ | 26 of 30 | **30 of 30** | wrong — every museum can host it |
| museums with ≥1 run of 8 m+ | 14 of 30 | **23 of 30** | wrong, 1.64× low |
| share of wall run in 1 m runs | 14% | **24.5%** | wrong, 1.75× low |
| mean run length | 4.4 m | **2.41 m** | wrong, 1.83× high |

I predicted a corpus of *moderately* long walls. **The corpus is bimodal and has
almost no middle.** 1241 runs are exactly 1 m (59% of all runs, 24.5% of all
length); 53 runs are 10 m or longer and carry 17.2% of all length on their own.
The mean of 2.41 m describes no wall in the building set.

That bimodality is why two true statements sound like a contradiction:
*"59% of every wall in the corpus is exactly one metre long"* (white_cube.md §1)
and *"55.1% of all wall run is already in runs a 4 m panel fits on"* are both
correct. The first counts runs, the second counts metres. **A design decision
taken from the first number alone will be wrong**, and white_cube.md §8 takes
one: it concludes "the only cure is editing `template_patterns.json` tiles".
Measured by length, the tiles need no cure at all.

---

## 1. THE TILE CORPUS, measured

`tools/em_module_measure.py`. It imports the occupancy mirror from
`em_white_cube_measure.py` verbatim (`map_vestibule`, `map_tile`,
`dressed_faces`, `stretches_of`) so the two reports cannot drift. It reproduces
white_cube.md's histogram exactly — 1241 / 233 / 499 / 78 / 53 walls — which is
the check that the new tool is measuring the same corpus.

**5071 m of wall run, 2104 runs, 30 museum-tagged patterns.**

| run length | share of all wall run | runs |
|---|---|---|
| ≥ 2 m | 75.5% | 863 |
| ≥ 3 m | 66.3% | 630 |
| **≥ 4 m** | **55.1%** | **440** |
| ≥ 5 m | 43.3% | 290 |
| ≥ 6 m | 27.6% | 131 |
| ≥ 8 m | 19.5% | 67 |
| ≥ 10 m | 17.2% | 53 |
| **= 1 m** | **24.5%** | **1241 (59% of all runs)** |

### Could a 4 m certified wall panel be hosted?

| | museums |
|---|---|
| ≥ 1 run of 4 m or longer | **30 of 30** |
| ≥ 1 run of 6 m+ | 26 of 30 |
| ≥ 1 run of 8 m+ | 23 of 30 |
| ≥ 1 run of 10 m+ | 19 of 30 |

**590 whole 4 m module slots exist corpus-wide, covering 46.5% of all wall run.**
The median museum has 13 of them. Tile-only, without the engine's shell: 456
slots, 42.6%, 27 of 30 museums, median 11. Either way the answer is the same and
it is not close.

### The 1 m wall cells: structural or incidental?

A 1 m run has exactly two causes, and the tool separates them by asking whether
the wall cell has a wall neighbour on its own axis:

- **PIER — 878 of 1241 (71%).** The tile authored a one-metre stub. Nothing but
  a tile edit lengthens it.
- **NO_FLOOR — 363 of 1241 (29%).** The wall continues; the *room in front of
  it* does not. The wall is long, the standing room is short. A tile edit is not
  the only cure here — a floor edit is another.

So 878 genuine 1 m piers carry 17.3% of all wall run, and 71% of the "59% of
walls are 1 m" headline is structural. It is real, and it is a minority of the
building by length.

---

## 2. WHAT "MODULAR" IS NOT YET TRUE OF

Three candidates were on the table. Two are already true and one is not.

### ✗ "Tiles encode 1 m cells rather than wall RUNS" — not the problem

True as a description, false as a fault. 55.1% of run is already ≥ 4 m and
30/30 museums host a 4 m panel. The tiles express long walls perfectly well;
they encode them cell by cell, which is a *notation*, not a limit.

### ✗ "There is no module inventory a human can lay out" — already exists

`commons/data/museum_module_kit.json` (schema `ada-museum-module-kit-v1`)
declares a 7-family wall kit at widths 1–4 cells, a socket contract
(`museum_wall_flat_v1`, `gallery_spine_3m`), named compositions
(`uffizi_north = service:2|feature:4|solid:2`), an 8×4×8 `uffizi_bay_v1` module
with part counts and a mesh budget, and an 11-gate certification list. The code
exists and works: `museum_wall_piece.gd`, `museum_wall_run.gd` (a one-line run
spec composer), `museum_wall_kit_atlas.gd`. Two certification maps exist and are
built: `Museum_AAA_Uffizi_Bay_V1`, `Museum_AAA_Uffizi_Bay_Seam_Test`.

**And it is orphaned.** Zero map in `commons/maps/` places `museum_wall_piece`,
`museum_wall_run` or `museum_wall_kit_atlas`. `endless_museum.gd` references
none of them. Its only live consumer is `gallery_walk.gd`, a scene launched by
hand.

**Wiring it into the museum would be a mistake, and this is the number that says
so.** `ada_run/museum_aaa_pass/museum_wall_aaa_static_profile.json`, the kit's
own certified profile:

```
corpus:          128 m of wall, 8 runs of the 16 m full-build spec
mesh_instances:  1416      multimesh_draws: 80
render_draw_nodes: 1496    ->  11.7 draw nodes per linear metre
```

Against the Endless Museum today at **1.0 draw node per linear metre** of wall,
and 0.137 after §4. The certified kit is **11.7× heavier than the museum's
current walls and 85× heavier than its merged ones.** The brief's word was
*lighter*. Whatever "shift the museum to become modular" means, it cannot mean
this — and nothing in the kit's own paperwork says so, because the kit was
certified against a 128 m bench, never against a 228-cell segment.

### ✓ "Walls are generated per-cell rather than assembled from runs" — this one

`endless_museum.gd:_build_segment` stamps a wall in five places, all identical:

```gdscript
_box(seg, Vector3(x + 0.5, 1.5, z + 0.5), Vector3(1, 3.0, 1), wall_col, m_wall)
_add_col(solid, Vector3(x + 0.5, 1.5, z + 0.5), Vector3(1, 3.0, 1))
```

One BoxMesh and one BoxShape3D per cell. **6826 wall boxes across the 30
museums, mean 228 per segment** — every one 1 m wide, none of them named, none
of them knowing it is part of a 34 m wall the engine can already describe
(`em_detail.stretches_of` computes exactly those runs, to hang pictures on
them). The plan layer knows about runs. The geometry layer does not.

That is the sense in which the museum is not built from modules, and it is the
only one of the three that is both true and worth fixing.

---

## 3. WHY NO TILE WAS EDITED

The brief's standing rule: template edits are authored data; edit tiles only if
the measurement shows the current ones cannot express what is needed.

The measurement shows the opposite. 30/30 museums host a 4 m module; 590 whole
4 m slots exist; 55.1% of all wall run is already ≥ 4 m. The tiles can express
it. **The test came back negative, so the tiles were not touched** —
`commons/data/template_patterns.json` is unmodified by this pass.

The 878 genuine 1 m piers remain a legitimate authoring question, and it is a
question about the Soane and the Mezquita specifically (316 of the Mezquita's
piers are its hypostyle forest — deleting them would delete the building's
argument). It is a human decision about buildings, not a measurement conclusion,
and it is left open.

---

## 4. THE CHANGE — merge collinear wall cells into one box per run

**Smallest change that makes the museum built from modules**: make the wall
*geometry* follow the runs the engine already computes for the wall *plan*.

`commons/scenes/endless_museum.gd`, two new functions and a gate:

| piece | what it does |
|---|---|
| `_wall_at()` | gate-aware stamp. Gate OFF: byte-for-byte the two calls it replaced, same order. Gate ON: records the cell. |
| `_stamp_wall_runs()` | greedy longest-first — take the longest straight run in the cell set, emit ONE box, remove its cells, repeat. |
| `--em-wall-runs` / `"wall_runs": true` | the two opt-ins, both default false, same shape as `--em-white-cube` |

**What it supersedes: nothing.** No authored data changes. No tile migrates —
the merge is derived from the same cell set the per-cell path reads, at build
time, so every existing tile works unedited and a tile authored tomorrow needs
to know nothing about it. It supersedes only the anonymous per-cell box, and
only when asked.

**Why the merge is safe, and this is load-bearing:** every architectural
material in the scene is WORLD triplanar (`em_materials._base` sets
`uv1_world_triplanar`). Its own header states the reason — *"the museum is built
from hundreds of separate 1 m boxes, and per-mesh UVs would stamp an identical
tile of noise into every one"*. A world-triplanar sample is a function of world
position, not of mesh UV, so an N-metre box and N one-metre boxes shade
identically. **There is no UV to stretch.** Solid volume is unchanged, so the
collider is unchanged. The one design decision that was taken years ago for a
different reason is what makes this merge free.

Compile-checked: `endless_museum.gd`, 1 checked, 0 failed.

### Measured, before and after

`tools/em_wall_merge_measure.py`, mirroring the same greedy rule.

| | BEFORE | AFTER | |
|---|---|---|---|
| wall boxes, 30 museums | **6826** | **936** | 7.29× fewer |
| wall boxes per segment (mean) | 228 | 31 | 196 fewer draw nodes, −86% |
| box length, mean | 1.0 m | **7.3 m** | |
| box length, max | 1 m | **40 m** | |
| draw nodes per linear metre of wall | 1.00 | **0.137** | |

Wall-box length distribution after the merge (before, all 6826 are 1 m):

| box length | boxes | metres | % of run | % of boxes |
|---|---|---|---|---|
| 1 m | 302 | 302 | 4.4% | 32.3% |
| 2 m | 87 | 174 | 2.5% | 9.3% |
| 3–5 m | 280 | 1118 | 16.4% | 29.9% |
| 6–9 m | 59 | 414 | 6.1% | 6.3% |
| 10–19 m | 96 | 1247 | 18.3% | 10.3% |
| ≥ 20 m | 112 | 3571 | **52.3%** | 12.0% |

Half the museum's wall length is now carried by 112 objects.

Per museum, best and worst: `pompidou-plateau-libre` 187 → 11 (17.0×),
`labrouste-stack-hall` 179 → 12 (14.9×), `mezquita-hypostyle` 242 → 87 (2.78×,
because it genuinely is a forest of piers), `guggenheim-serpentine` 121 → 36
(3.36×, a curve approximated in steps). Full table in
`doc/reports/em_wall_merge.json`.

**Note precisely what did NOT change: the wall-run distribution of §1.** The
face runs a picture can hang on are identical before and after — 55.1% ≥ 4 m
either way — because the cell set is identical. This change did not make the
walls longer. It made the wall *objects* match the walls that were already
there. Any report claiming this pass lengthened a wall would be wrong.

---

## 5. PROOF — the running engine, same museum, same seed

Godot 4.6, `--xr-mode off --no-window`, wrapped in `tools/godot_watchdog.py`,
one instance at a time. BEFORE and AFTER differ by the single flag
`--em-wall-runs`.

```
res://commons/scenes/endless_museum.tscn -- [--em-wall-runs] \
    --em-first=uffizi-spine-enfilade --em-shot=user://wr_<x>_uffizi.png --em-segments=2
```

| PNG | mtime | bytes |
|---|---|---|
| `user://wr_before_uffizi.png` → `doc/reports/museum_modularity_before_uffizi.png` | 2026-08-13 10:52:02.732 +0200 | 1 700 547 |
| `user://wr_after_uffizi.png` → `doc/reports/museum_modularity_after_uffizi.png` | 2026-08-13 10:52:25.513 +0200 | 1 692 100 |

`user://` = `C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/`.
`.gitignore:373` ignores `doc/reports/**/*.png`, so the `user://` paths are
canonical. Both 1800×1200. The `doc/reports/` copies are mtime 10:55:42 (the
copy, not the render).

### The frame delta — the whole point

```
mean luminance   BEFORE 56.70   AFTER 56.62   (-0.08)
pixels differing by >0  : 19.568%
pixels differing by >8  :  0.000%
pixels differing by >32 :  0.000%
max channel delta       : 16 / 255
```

**Nine times fewer wall objects and the picture is the same.** For scale: the
white-cube change on this same frame moved 23.95–29.51% of pixels by more than
8/255 and mean luminance by +6. This moves 0.000% by more than 8. The residual
is shadow-map sampling on fewer, larger casters, and it is sub-perceptual. Both
frames were opened and compared by eye as well as by arithmetic; they are
indistinguishable.

That is exactly what world triplanar predicts, and it is the evidence that the
merge is a change of *objecthood*, not of appearance.

### The engine's own log

```
BEFORE  logs/godot2026-08-13T10.52.07.log     (zero [em_wall_runs] lines)
  [em_detail] walls: 170 dressed faces, licence 50, 50 showings hung (min wall 2 m)
  seg 0 = uffizi-spine-enfilade   placed 16/16 + 2 plinths + 16 props, lights 22
  [em_detail] walls: 205 dressed faces, licence 52, 52 showings hung (min wall 2 m)

AFTER   logs/godot2026-08-13T10.52.39.log     --em-wall-runs
  [em_wall_runs] 202 wall cells -> 22 boxes (9.18x fewer), longest run 34 m
  [em_detail] walls: 170 dressed faces, licence 50, 50 showings hung (min wall 2 m)
  seg 0 = uffizi-spine-enfilade   placed 16/16 + 2 plinths + 16 props, lights 22
  [em_wall_runs] 203 wall cells -> 29 boxes (7.00x fewer), longest run 34 m
  [em_detail] walls: 205 dressed faces, licence 52, 52 showings hung (min wall 2 m)
```

Every downstream number is identical: dressed faces 170/205, licence 50/52,
showings 50/52, artifacts 16/16 and 14/14, plinths, props, lights 22. Only the
wall box count moved. And the engine's `202 -> 22, 9.18x, 34 m` matches the
Python mirror's row for `uffizi-spine-enfilade` (202 cells, 22 boxes, 9.18,
max 34) **exactly**.

One honest discrepancy: segment 1 logs 203 cells where the mirror says 216 for
`sainsbury-false-perspective-enfilade`. The mirror measures every museum as if
it were segment 0 (`prev_w = -1`); live, segment 1 inherits the Uffizi's width
15, so the lobby's "seal behind" strip is shorter. The mirror is right about
segment 0 and conservative about the rest.

### File ordering (not open to interpretation)

```
10:40:58  doc/reports/museum_modularity_prediction.txt   <- prediction
10:42:07  tools/em_module_measure.py                     <- first instrument
10:47:40  tools/em_wall_merge_measure.py
10:51:13  commons/scenes/endless_museum.gd               <- the only edited file
10:52:02  wr_before_uffizi.png
10:52:25  wr_after_uffizi.png
```

---

## 6. What is still open

- **The gate is off for everyone.** `--em-wall-runs` is a run flag; the
  per-template `"wall_runs": true` is honoured and set on none of the 30.
  Turning it on by default is a one-line decision that should be taken by a
  human who has walked a merged museum in VR, not inferred from a still.
- **Only one museum was photographed.** A concurrent Godot instance started at
  10:55:20 and the rule is one at a time, so the Mezquita pair — the corpus's
  hardest case at 2.78× and 316 piers — was not shot. Its merge is measured but
  not seen. That is the first thing the next pass should capture.
- **The orphaned kit needs a decision, not more certification.** 7 families,
  1–4 m widths, an atlas, a socket contract, two certification maps, eleven
  gates, and no museum. Either it becomes the museum's wall vocabulary at a
  fraction of its current 11.7 draw nodes/m, or it is honestly retired to the
  bench it lives on. It should not stay certified and unused.
- **The 878 piers.** Named, counted, per museum, and deliberately not touched.
- **"Lighter" was read as draw nodes.** 7.29× fewer wall objects answers the
  geometry reading. Triangle count is nearly unchanged (a box is a box), so if
  the brief meant fill rate or vertex count, this is not that change.

---

## Files

| path | role |
|---|---|
| `doc/reports/museum_modularity_prediction.txt` | the prediction, 69 s older than the first instrument |
| `tools/em_module_measure.py` | run-length / 4 m-hostability / pier-vs-no-floor measurement (new) |
| `tools/em_wall_merge_measure.py` | the merge mirror; source of 6826 → 936 (new) |
| `doc/reports/em_wall_merge.json` | per-museum merge table |
| `commons/scenes/endless_museum.gd` | `_wall_at`, `_stamp_wall_runs`, `--em-wall-runs` (the only file edited) |
| `doc/reports/museum_modularity_{before,after}_uffizi.png` | the proof pair |
| `commons/data/museum_module_kit.json` | the certified, orphaned kit — read, not edited |

`commons/data/template_patterns.json` unchanged. Not committed.
