# Order to walk — does the corridor deal the curriculum in curriculum order?

Status: session evidence (Level C). Canonical parent: `doc/SPATIAL_PIPELINE.md`
Audited 2026-08-12. Read-only pass over the dealer; nothing in the museum was changed.

The chain under test:

```
commons/maps/curriculum_spine.json
  -> tools/build_spine_artifact_order.py
  -> commons/data/spine_artifact_order.json          799 rows
  -> endless_museum.gd::_load_spine_pool             756 alive
  -> endless_museum.gd::_pick_pool                   hands them out
  -> endless_museum.gd::_deal_segment                one sequence per museum
  -> em_sets.gd::_slot_before                        decides WHICH CELL
  -> a walker meets them, one after another
```

---

## PREDICTION (written before the run)

**Predicted sequence MIXES across 6 segments: 2.**

A *mix* is one segment whose curriculum **leads** come from more than one sequence —
the banner names one chapter and the room holds another.

The arithmetic behind the guess: `_deal_segment` hands the chapter opener back to the
next building only when `sq != seg_seq and sq != "" and placed >= 4`. The `placed >= 4`
clause means any boundary crossed while the room holds fewer than four objects is
absorbed silently. `em_budget` licenses some buildings at 1 and 4 objects, so those
buildings can never fire the guard at all. Over 6 segments I expect roughly 60-120
tokens to be dealt, i.e. 2-4 sequence boundaries crossed, of which I expect about half
to land under the `placed >= 4` floor. Hence 2.

**MEASURED across 6 segments: 0.** The prediction was wrong, and wrong in the way that
mattered: I assumed a building consumes chapters. It does not — six buildings consumed
**35 of the 82 `primitives` artifacts** and never reached a boundary. The guard was
never tested. So I ran it again at 16 segments to reach one, and there the prediction
turns out to have been right about the mechanism and low on the count:

**MEASURED across 16 segments: 3 mixes, in 3 of 3 boundary segments** (segs 13, 14, 15).
Every single building that met the `primitives -> transformation` boundary mixed.

---

## 1. The measured drift, stated plainly

Two runs, both spine order, both via `tools/godot_watchdog.py`, stdout captured with
`--log-file` (the non-console 4.6 exe writes nothing to a redirected pipe):

```
Godot_v4.6-stable_win64.exe --path . --xr-mode off --no-window --log-file <log>
  commons/scenes/endless_museum.tscn -- --em-shot=user://em_order_probe.png --em-segments=6
```

Note for the next agent: `--em-segments=N` alone builds **2** segments. `_ready()` reads
`preload_n = _shot_segments if _shot_path != "" else 2` — without `--em-shot` the flag is
inert and the scene then idles forever under `--no-window`. The shot flag is what makes
the segment count real.

| what is being ordered | n | pairs | inversions | Kendall tau |
|---|---|---|---|---|
| **leads**, deal order vs curriculum, 6 segments | 35 | 595 | **24** | **+0.919** |
| **leads**, deal order vs curriculum, 16 segments | 81 | 3240 | **151** | **+0.907** |
| **all stamped bodies** (leads + relatives), 6 segments | 62 | 1872 non-tied | **512** | **+0.453** |
| **walk order vs deal order inside one Sainsbury** | 14 slots | 91 | **39** | **+0.143** |
| same, mean over all 26 museum templates | — | — | — | **+0.401** |

Read those four rows as one sentence: **the pool is nearly perfect, the deal is good, the
set-deal halves it, and the architecture throws most of the rest away.** The curriculum
survives every step except the last one — the step where it becomes a walk.

### 1a. The pool is honest
`_load_spine_pool` preserves manifest order exactly. For the 41 curriculum positions this
run touched, pool index == curriculum index for every one.

### 1b. `_pick_pool` costs 24 inversions and one long-range displacement class
Max rank displacement over 6 segments is 9 positions, mean 1.37 — the local 16-deep
footprint swap, working as documented. But the swap **mutates `_pool`**: the artifact at
the cursor is pushed to `cursor+off`, up to 15 places later, and a token rejected
repeatedly compounds. Over 16 segments that produced:

- `science_screen` (curriculum #9) dealt as the **58th** lead — 49 positions late;
- `folded_strip` (#37) dealt 72nd; `grid_lines` (#31) dealt 43rd; `triangle` (#39) dealt 44th.

Three of those four are also on the missing-artifact list below, which is a coincidence
worth noting: the same artifacts are unlucky twice.

### 1c. The relatives are the real order drift, and it is by design
`em_sets` deals a lead with its authored neighbours. Those neighbours come from
`artifact_relations.json` **by name**, with no reference to curriculum position, so an
`axis_kin` can be anything in the corpus. In the first two buildings of chapter one the
walker meets:

| relative | dealt in | curriculum # | its actual chapter |
|---|---|---|---|
| `VectorBasics` | seg 0 | 248 | forces |
| `csg_compose_workbench` | seg 0 | 678 | boolean_surfaces |
| `curvature_slider` | seg 1 | 726 | foundationscrisis |
| `complexity_pattern` | seg 2 | 771 | qfeplaboratory |
| `provability_sorter` | seg 3 | 736 | foundationscrisis |

In the third room of the book the walker is standing next to artifact 771 of 799. That is
the whole of the 0.919 -> 0.453 collapse. It is not a bug — the set deal exists to put an
argument beside its kin — but nobody had put a number on the price, and the price is
**half the curriculum ordering**.

### 1d. Twelve tokens are met more than once in six buildings
`player_trace` x4, `plus_line_puzzle` x3, and nine others x2. Most are cross-segment
(relative in one building, lead in a later one). Three are **inside one room**:
`fontana_puncture` (seg 0), `laser_exploding_sphere` (seg 3), `cube_scene` (seg 2, three
times). Cause: `_deal_segment` checks `seg_tokens` before stamping a **relative** but not
before stamping a **lead** (`endless_museum.gd:1429-1440` vs `:1475`), so a token already
standing in the room as somebody's neighbour is dealt again a few slots later as itself.

---

## 2. The 43 missing, grouped by why

756 of 799 are alive. The 43 fall into three causes, and they are not spread evenly —
**43 artifacts, but only 8 of 24 sequences are touched, and two chapters take 26 of them.**

**(a) Registry row exists, `scene` field is empty — 30 artifacts.** These were never built;
the row is a placeholder. Concentrated hard:

- *color* (18): the whole `Color_Context_Placed` DNA set — `dna_color_stacks_*` (6),
  `dna_color_furniture_*` (4), `dna_modern_art_*` (4, incl. `albers_homage_warm`,
  `rothko_chromatic_field`, `mondrian_de_stijl`, `kandinsky_bauhaus_triad`),
  `dna_primitive_stack_ps01_bauhaus_totem_green`, `loom_drum_bauhaus_p4m`,
  `loom_fountain_pastel_p4`, plus `mill_memphis_p3` and `loom_drum_persian_p6`.
- *symmetry* (6): `mill_persian_p4`, `mill_escher_p4g`, `loom_escher_mirror`,
  `loom_bolt_memphis_p4g`, `loom_alhambra_p6m`, `mill_alhambra_p6m`.
- *forces* (6): the XL laser vector family — `vector_addition_xl_laser`,
  `vector_subtraction_xl_laser`, `vector_addition_xl`, `vector_dot_product_xl`,
  `vector_cross_product_xl`, `vector_projection_reflection_xl`.

**(b) Scene exists on disk, `map_ready` is false — 12 artifacts.** These are built and
withheld: `translation_cube_demo`, `pattern_atlas_gallery`, `color_sets_overview`,
`momentum_collision`, `hazards_demo`, `nature_system_demo`, `box_counting_dimension`,
`mamma_monster_gallery`, `tt`, `snap_cube_puzzle`, `snap_tetra_puzzle`,
`bifurcation_walkway`. This is the cheap tranche — a flag, not a build.

**(c) No registry entry at all — 1 artifact.** `calder_mobile_primaries`, named by
`Sky_Climb` in *forces*. A map references a token no registry file defines.

### Does the absence break a teaching sequence?

| sequence | of | gone | % | chapter opener | map openers lost |
|---|---|---|---|---|---|
| **qfeplaboratory** | 31 | 4 | 13% | **NO — `tt` is gone** | QFEP_Introduction, QFEP_F_Term |
| **color** | 50 | 19 | 38% | alive | — |
| **symmetry** | 21 | 7 | 33% | alive | Symmetry_Mirror_Rotor, Symmetry_Glide, Symmetry_Group |
| forces | 151 | 8 | 5% | alive | Force_Preview, VectorOperations, ForcesComposition |
| lsystems | 16 | 1 | 6% | alive | Assemblage_Same_Desire |
| randomness | 64 | 2 | 3% | alive | — |
| transformation | 24 | 1 | 4% | alive | — |
| fractals | 45 | 1 | 2% | alive | — |

**One chapter loses its opener: `qfeplaboratory`.** Its first artifact in curriculum order
is `tt` (map `QFEP_Introduction`), and `tt` is built but not `map_ready` — cause (b), the
one-flag tranche. Every other chapter still opens with the artifact the spine says opens
it. The remaining 42 are footnotes by that test.

But two chapters are gutted below the opener, and the museum will feel it, because a
building holds ~5 leads:

- **color loses 38%**, 17 of them from the single map `Color_Context_Placed` (17 of its 23).
  That map's contribution to the corridor is essentially deleted.
- **symmetry loses 33%**, including the first artifact of three of its maps and 3 of the 5
  in `Symmetry_Seventeen`.

At 5.06 leads per building (measured: 81 leads / 16 buildings), losing 19 of color's 50 is
losing roughly **four whole buildings** of that chapter. Not a footnote.

---

## 3. Does the one-sequence-per-museum rule hold?

**In the 6-segment run: vacuously yes.** All six buildings were chapter `primitives`, and
all six were the *same building* — `sainsbury-false-perspective-enfilade`, six times. The
rule was never exercised.

**In the 16-segment run: no. It failed in 3 of the 3 buildings that met a boundary.**

```
seg 0..12   primitives                    sainsbury, thirteen times, back to back
seg 13      primitives + transformation   <<< MIX   placed 5/14   building = Sainsbury (14th)
seg 14      primitives + transformation   <<< MIX   placed 5/16   building = Uffizi
seg 15      primitives + transformation   <<< MIX   placed 5/18   building = Grande Galerie
```

Three separate faults are visible in those three rows:

1. **The `placed >= 4` floor lets exactly one artifact of the next chapter through.** In
   seg 13 the lead `combine_portals` (primitives) plus its neighbour left `placed` at 3;
   `homogeneous_coordinates` (transformation) was therefore under the floor, was dealt,
   and only the lead *after* it tripped the guard. Same shape in 14 and 15.
2. **The boundary costs the building ~65% of its licence.** The guard `break`s the deal
   loop, so segs 13-15 placed 5 of 14/16/18 and the remainder went to guests. Three
   buildings in a row are two-thirds empty of curriculum at every chapter change.
3. **The building is chosen from a peek that `_pick_pool` then contradicts.**
   `_build_segment:938-948` reads `_pool[_pool_i].sequence` to look up the crown, but
   `_pick_pool` may swap a different artifact into that cursor. Seg 14 was therefore
   dealt the **Uffizi** (the crowned building of `postfoundationscrisis`) and then filled
   with `primitives`. Seg 15 got the **Grande Galerie** (crowned for `change`, `lsystems`,
   `graphtheory`, `foundationscrisis`) and filled it with `primitives` too.

And one structural consequence nobody has stated as a number: **a crowned chapter is one
building repeated for its whole length.** `use_crown` skips `_rot_i += 1`, so the rotation
never advances while the crown holds. Measured: **fourteen consecutive identical Sainsbury
Wings** (segs 0-13) before the building changed, and it only changed because the boundary
peek fell through to the rotation. Walking the whole 799-token spine at 5.06 leads per
building needs about **158 buildings**, of which the first fourteen are the same room.
"Endless museum" is currently endless in the wrong axis.

---

## 4. The single most damaging order defect

**`commons/scenes/em/em_sets.gd::_slot_before` (line 778) — it sorts candidate cells by
`rank` before `y`, so the chapter's first artifact is dealt to the deepest cell in the
building and the walker meets the curriculum roughly backwards.**

Co-cause: `endless_museum.gd::_build_segment` line 1029,
`slots.sort_custom(func(a,b): return int(a["rank"]) < int(b["rank"]))`, which hands
`_free_slots` a rank-ordered list in the first place. `em_sets` then re-sorts it
`(rank, y, x)` and comments the intent honestly: *"the lead takes the best slot: lowest
rank, then nearest the entrance"*. Rank dominates. Nearest-the-entrance only breaks ties.

Measured on the Sainsbury, from the real template plus that rule:

```
slot z in deal order        : 32, 13, 19, 32, 32, 7, 7, 12, 14, 18, 19, 24, 25, 26
deal-rank met in walk order : 5, 6, 7, 1, 8, 9, 10, 2, 11, 12, 13, 3, 0, 4
                              n=14  pairs=91  inversions=39  tau=+0.143
```

The chapter's **first** piece stands at z=32, the deepest cell in a 30-cell building. The
**sixth** stands at z=7, three metres past the door. A walker entering the Sainsbury meets
the chapter's sixth, seventh and eighth artifacts first and its first artifact last.

It is not one template's quirk. Over all 26 museum-tagged templates the mean tau of walk
order against deal order is **+0.401**, and in **10 of 26** the first-dealt slot is the
single deepest slot in the building (uffizi, guggenheim, castelvecchio, grande-galerie,
kanazawa, chichu, louisiana, labrouste, castelvecchio-pinch-v2, and the Soane at 96%).
`chichu-buried-cells` measures **tau = -0.200**: there the walk is worse than random.

Why this outranks the other defects: `_pick_pool`'s swap costs 24 inversions in 595 pairs
and the relatives cost 512 in 1872, but both are *reorderings of what is dealt*. This one
is the only defect that acts on **what the body meets**, it acts on every artifact in
every building, and it is invisible to every check in the chain — the pool is right, the
deal log reads in perfect curriculum order, the pathfinder passes, and the walk is still
scrambled. A reader of stdout would conclude the corridor is ordered. It is not.

The fix is one line and belongs to `em_sets`, not to the museum: order candidate cells by
`y` first for the *lead's* choice (keep rank as the tiebreak, or as a separate quality
filter), so the chapter's opening statement is the first thing past the threshold. That is
a change to a module another agent is holding, so it is named here and not made.

---

## Method notes / what is not measured

- The world positions of stamped artifacts are **not printed** by the museum
  (`_shot_targets` is built at `endless_museum.gd:1820` and only its *count* reaches
  stdout). I was write-restricted to this file, so no probe script was added.
  The walk-order figures are therefore derived from `template_patterns.json` plus the
  cell rule in `em_sets._slot_before`, **verified against three independent numbers the
  run did print**: the museum's own `z-spread` lines for segment 0 were 1
  (`frame_counter_display`), 25 (`you_are_here`) and 12 (`fontana_puncture`), and the
  reconstruction reproduces all three exactly. That is what makes them measurements
  rather than a reading of the source.
- Deal order is used as the proxy for encounter order **between** buildings (valid — the
  segments are laid out sequentially in +z) and corrected by the table above **within**
  a building.
- Both runs were `--em-order=spine`, no `--em-plan`, all twelve modules loaded
  (`sets/multiples/budget/plinths/props/pool` all true). Guests are excluded from the
  ordering figures by construction — they are not curriculum.
- Artifacts: `em6.log`, `em16.log` in the session scratchpad; proof frames at
  `user://em_order_probe.png` and `user://em_order16.png`.
