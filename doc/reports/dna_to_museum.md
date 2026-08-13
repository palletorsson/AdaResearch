# Does a walker in the endless museum ever meet a DNA variant?

Measured 2026-08-12. Read-only pass: nothing outside this file was edited.

Run under test:

```
python tools/godot_watchdog.py --expect="<user>/em_dna_probe.png" --grace=200 --stall=60 -- \
  "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off --no-window \
  res://commons/scenes/endless_museum.tscn -- \
  --em-first=uffizi-spine-enfilade --em-segments=3 --em-shot=user://em_dna_probe.png
```

Exit 0 in 25 s. Stdout recovered from `user://logs/godot.log` (`file_logging` is on in
`project.godot`, which is the only way to read a non-console 4.6 run).

**Gotcha, cost one run to find:** `--em-segments=N` is read only when a shot path is
also given — `endless_museum.gd:215` is `var preload_n := _shot_segments if _shot_path != "" else 2`.
`--em-segments=3` on its own builds two segments.

---

## 1. How much of the museum's pool is a family rather than an object

| what | count |
|---|---|
| registry entries scanned (`commons/artifacts/registry/*.json`) | 2728 |
| **promoted — entry declares a non-empty `dna.axes`** | **735** |
| declared axes across them | 1013 |
| spine order rows (`commons/data/spine_artifact_order.json`) | 799 |
| spine rows that are promoted | **504** |
| of those, ALIVE (`map_ready` + scene on disk) — i.e. actually in the pool | **496** |
| the museum's pool as the run reported it | 756 of 799 |

So **496 of the 756 artifacts the corridor can deal (65.6%) are families, not objects.**

CLAUDE.md's "184 of 2671 artifacts are promoted, 258 axes declared" is stale by a factor of
four. The run's own line agrees with the registry and not with the doc:
`[endless_museum] dna: 735 promoted tokens handed to em_multiples`.

`tools/check_dna_declarations.py` is clean: 1013 declared axes, 1000 verified,
**0 with an undeclared code value, 0 broken**, 13 unverifiable (12 sceneless `living_*`
grammar tokens plus `lineage_vitrine.subject` and `sturtevant_bench.subject`). The
science_screen class of failure is not currently in the registry.

---

## 2. What the run actually stamped

Per-segment lines, verbatim from the log:

```
seg 0 = uffizi-spine-enfilade      chapter=primitives placed 16/16 (7 leads, 5 relatives, 4 repeats, 2 guests)
seg 1 = sainsbury-false-perspective chapter=primitives placed 14/14 (6 leads, 5 relatives, 3 repeats, 0 guests)
seg 2 = sainsbury-false-perspective chapter=primitives placed 14/14 (6 leads, 5 relatives, 3 repeats, 0 guests)
deal: 46 objects across 3 segments (15.3 per segment; v1 ceiling was 8)
```

19 objects were HANDED a non-default axis value: 10 repeats (`em_multiples`), 7 `axis_kin`
relatives (`em_sets`), 2 guests (`em_pool`). Each was then checked against its own script —
does the axis exist as an `@export` on the scene ROOT, is the value inside the code's enum,
and does it differ from the value the code ships:

| kind | token.axis = value | verdict |
|---|---|---|
| repeat | frame_counter_display.reading=rate (ships `count`) | **applies** |
| repeat | you_are_here.deixis=words_only (ships `words_and_marks`) | **applies** |
| repeat | fontana_puncture.breach=pierced (ships `opened`) | **applies** |
| repeat | floating_sphere_field.density=scarce (ships `sparse`) | **applies** |
| repeat | folding_past.recession=collapsed (ships `nested`) | **applies** |
| repeat | lab_room.premises=workshop (ships `chamber`) | **applies** |
| repeat | laser_sword.repose=pilot (ships `dark`) | **applies** |
| repeat | science_screen.surface=curve (ships `plane`) | **applies** |
| repeat | cube_scene.grain=split (ships `solid`) | **applies** |
| repeat | parallel_line_puzzle.pair_pose=oblique (ships `upright`) | **applies** |
| axis_kin | csg_compose_workbench.strike=raised (ships `corner`) | **applies** |
| axis_kin | fractal_recursion_2.recession=collapsed (ships `nested`) | **applies** |
| axis_kin | grabbable_line.grain=split (ships `solid`) | **applies** |
| guest | combine_capsule.taxonomy=heap (ships `table`) | **applies** |
| guest | combine_sphere.taxonomy=heap (ships `table`) | **applies** |
| axis_kin | VectorBasics.reading=**full** — `full` IS its shipped default | no-op |
| axis_kin | curvature_slider.witness=**number** — its shipped default | no-op |
| axis_kin | catalyst_target.support=**none** — its shipped default | no-op |
| axis_kin | complexity_pattern.readout=**relief** — its shipped default | no-op |

> **19 handed → 15 that actually differ from the artifact's own default.**
> 15 of 46 dealt objects, **33% of what a walker meets in three rooms**, and 5 per segment.

The log carries independent confirmation that the geometry really changed. `parallel_line_puzzle`
prints its own build line, and the two copies printed different ones:

```
ParallelLinePuzzle: 2 lines, 4 vertices, pose=upright stock=parallel, ...
ParallelLinePuzzle: 2 lines, 4 vertices, pose=oblique stock=parallel, ...
```

So the answer to the headline question is yes — and the CLAUDE.md "KNOWN GAP" note
("outside Artist_Readymades nobody has ever met a variant") is now out of date for the
museum, which is the second place in the project where variants reach a body.

### THE PREDICTION, AND WHERE IT WAS WRONG

Written before the run (scratchpad, 21:55 CEDT), predicted **22** non-default stamps:
13 repeats + 7 guests + 2 relatives. Arithmetic assumed the buildings would be
uffizi (mult 2), grande-galerie (mult 2), altes (mult 4), from `em_order` in
`template_patterns.json`.

Measured 19 handed / 15 effective. Two of the three components were wrong, in ways that
matter more than the total:

* **Guests: predicted 7, measured 2.** Segments 1 and 2 printed
  `guests: none — every slot in this building is spent`. The guest phase only sees cells
  the deal loop declined, and in a building whose budget matches its slot count there are
  none. 64 of the 134 guests carry a registry-confirmed rendered axis value — the cheapest
  variant the museum can show — and in two rooms out of three that route delivered zero.
* **The rotation does not happen.** I predicted three different buildings; the run gave
  uffizi once and sainsbury twice. `_load_crowns` /
  `commons/data/museum_crowns.json` crowns the `primitives` chapter to
  `sainsbury-false-perspective-enfilade`, and `_build_segment` gives a crowned chapter its
  crowned building for as long as the chapter lasts. **A 3-segment run is one forced
  building plus the chapter's crown, twice — not a sample of the corpus of 26.** Altes'
  `mult: 4`, the only high-multiples building I had in the estimate, never ran. Every
  repeat in this run was `x2` because both buildings license `mult: 2`, so the *building*,
  not the artifact, set the variant count on every single lead.

---

## 3. Does `_apply_axis` change the object, or fall back silently?

`endless_museum._apply_axis` (line 1938) delegates to `em_multiples.stage()`, which is the
right gate and does the right things in the right order — coerce to the export's type, set
`config_<axis>` metadata, write the property, defer `apply_grid_config`, all BEFORE
`add_child` so `_ready()` builds the variant rather than the default. It also refuses a
value outside the code's `@export_enum` and warns by name, and refuses a value equal to the
one the node already ships. **That refusal is why 4 of the 19 above are no-ops rather than
lies: the code was honest, the value it was handed was not new.**

Two real holes, both measured:

**(a) `stage()` only looks at the ROOT's property list, while the rest of the project
searches breadth-first.** `_prop_info(node, axis)` scans `node.get_property_list()` and
nothing else. When it finds nothing, `code_values` is empty (so the enum gate is off),
`shipped` is empty (so the "already ships as this" guard is off), the first candidate is
accepted, `node.set(axis, typed)` is **skipped**, and `apply_grid_config` is called only if
the root happens to have it. For a `.tscn` whose script sits on a child and whose root is
scriptless, **`stage()` returns `{ok: true}` having changed nothing** — and `ok: true` means
`drop_if_unvaried` will not drop it, so a twin ships and the log says the axis was applied.

Static scan of the 710 declared axes on spine-promoted tokens:

| where the axis lives | count |
|---|---|
| `@export_enum` on the scene root | 567 |
| plain `@export` on the scene root | 94 |
| on a CHILD script (root cannot see it) | 46 |
| no `@export` found anywhere | 3 (`draw_dot_time_domain.retention`, `layered_membrane.registration`, `nakama_metaballs.imprint`) |

**35 spine-promoted tokens have no axis on their scene root at all** — `line`, `laser_measure`,
`bernini_columns`, `GyroidDemo`, `transformation_cube`, the four `example_2_*_vr` force
benches, the grab spheres, and more. `GridInteractablesComponent._config_holder`
(GridInteractablesComponent.gd:1712) already solves exactly this, breadth-first, with a
comment saying the bench looked harder than the world did. `em_multiples.stage()` has not
been given the same eyes. None of the 35 was dealt in this run, so the trap is armed, not
sprung.

**(b) The enum gate cannot bite on 94 of 710 axes.** `_enum_values()` returns `[]` unless
the hint is `PROPERTY_HINT_ENUM`, and for a plain `@export var x: String` the module applies
whatever it was handed. That is correct today (`check_dna_declarations.py` reports 0
mismatches) and it is the exact shape of the science_screen failure if a declaration ever
drifts, on 13% of the corpus's axes.

---

## The single change that would most increase how often a walker meets a real variant

**`commons/scenes/em/em_sets.gd` → `_axis_pair()`** — when choosing `rel_value`, skip the
candidate's OWN shipped default, exactly the way `em_multiples._default_for()` already
parses it out of `dna.default`.

Today the function takes the first declared value that is neither the lead's value nor
already used:

```gdscript
for v in cv:
    var s: String = String(v)
    if s == lead_value or used.has(s):
        continue
    rel_value = s
    break
```

It never asks what the relative ships as. **81% of the promoted spine tokens whose
`dna.default` parses (232 of 288) have their default sitting at `axes[axis][0]`** — the very
first value this loop reaches. Measured in the run: 4 of 7 `axis_kin` relatives (57%) were
handed their own default, `stage()` correctly refused all four, and four objects that the
segment summary announced as variants (`VectorBasics(axis_kin reading=full)`) stood in the
room as ordinary defaults. Fixing it converts those four into real variants:
**15 → 19 per 3-segment run, +27%, with no change to any budget, mechanism or corpus law.**

Runners-up, with their measured sizes:

1. **`em_multiples.stage()` → `_prop_info()`**: walk the subtree breadth-first (mirror
   `GridInteractablesComponent._config_holder`) instead of reading the root only. Worth 0
   in this run and 35 spine tokens / 46 axes across the pool — and it closes a silent
   `ok: true` that no gate downstream can catch.
2. **`endless_museum._deal_segment`, the guest block (~line 1522)**: the guest phase is the
   only route that can put a *rendered, human-inspected* value in a room, and it returned 0
   in two rooms of three because the deal loop had spent every cell. Reserving one slot per
   segment for a guest would have added ~2 more variants here.
3. **`commons/data/artifact_relations.json`**: 23 of the 496 promoted-and-alive spine
   tokens carry `multiples: 1` (and an empty `axes` block) because the file was generated
   when 481, not 504, tokens were promoted. Those 23 can never be shown twice however
   generous the building. Regenerating the relation file is a data fix, not a code one.
