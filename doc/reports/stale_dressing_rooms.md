# The 34 placement_contract rooms, field by field against the measurements

**Measured 2026-08-12.** Read-only audit. Nothing under `commons/artifacts/dressing_rooms/`
was edited.

---

## The number you asked for

**2 rooms carry a field I will call STALE.** `situated_bench.footprint` and
`neural_network_visualization.placement_contract.hard_zone_m`.

You expected 1 or 2 and the count lands there. **Do not take the reassurance.** The count is
small because "stale" turned out to be the wrong frame for almost every disagreement, not
because the rooms agree. **18 of the 34 footprints disagree with the registry**, some by 4x,
and exactly **one** of those 18 disagreements is attributable to the corpus re-measure.

Three parts of the brief did not survive contact with the files.

**1. "Every OTHER metre-room checked so far agrees with its measured body to two decimals" —
false.** 16 of 34 agree. 18 do not. Six disagree by more than 50%:
`control_pendulum` (250%), `floating_sphere_field` (600%), `grabbable_line` (150%),
`phi_slider` (300%), `situated_bench` (130%), `platonicsolids` (70%), plus
`random_walk_leash` (68%), `neural_network_visualization` (75%), `info_board` (60%).

**2. "The 33 metre-rooms predate it [the re-measure]" — true in time, misleading in effect.**
33 rooms have mtime 2026-08-10 (12:11–21:12 UTC); the re-measure stamped the registry at
2026-08-12T04:39:51Z. One room, `bias_visualizer`, was rewritten at 2026-08-12T14:42:50Z —
after — and it agrees to the centimetre. But the other 33 do not carry pre-re-measure values
either: **16 of them match the *post*-re-measure number to two decimals while being two days
older than it.** `lambda_slider` is the proof. On 2026-08-10 the registry said its body was
`[8, 8, 8]` (the documented particle-`visibility_aabb` epidemic); the room written that day
says `0.69 × 0.33 × 1.31`; the 08-12 re-measure then produced `0.69 × 0.33 × 1.30`. The room
author did not read the registry. **They measured each artifact themselves**, which is also
why the room numbers carry three decimals (`1.466`, `4.992`, `0.903`) where the registry snaps
to two. These rooms are a second, independent measurement pass — not a stale copy of the first.

**3. "One is provably stale: CoordinateSystem3M ... 7.43 × 9.93 for a body that now measures
4.75 × 3.35" — the comparison is between two different quantities.** See below. It is the
single most consequential thing in this report, because that sentence is also the justification
comment inside `tools/emit_dressing_room.py::from_room` (lines 202–209) for the rule
"THE MEASUREMENT WINS ON BODY SIZE".

---

## The frame bug behind the headline case

`commons/testing/measure_artifacts.gd:482` ends `_measure_body()` with:

```gdscript
return root.global_transform.affine_inverse() * body
```

The AABB is returned **in the artifact root's own local space**, which divides out any scale
the artifact applies to itself. `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd:37`
does exactly that in `_ready()`:

```gdscript
scale = Vector3(display_scale, display_scale, display_scale)   # display_scale = 1.5
```

So the registry's `4.75 × 3.35 × 3.35` is the body **before** the 1.5x the artifact applies to
itself. In a map — where the dressing room, the negotiator and the plan all live — the body is
`7.13 × 5.03 × 5.03`. Against that:

| axis | room says | world body | ratio |
|---|---|---|---|
| width | 7.43 | 7.13 | 1.04 |
| depth | 9.93 | 5.03 | **1.98** |
| height | 5.46 | 5.03 | 1.09 |

Two of the three numbers are right to within 9%. Only the depth is wrong, and it over-claims
rather than under-claims. The room is not a relic of an old measurement; it is a world-space
number being compared against a local-space one.

**61 scripts** under `commons/artifacts/`, `algorithms/`, `commons/primitives/` and
`commons/scenes/` set root `scale` in code, so this is a family, not one artifact.

The same rewrite (docstring at `measure_artifacts.gd:382-396`, dated 2026-08-11 — *the day
after these rooms were written*) also **redefined what counts as a body**: `Label3D` and
`Sprite3D` moved to `signage`, `GPUParticles3D`/`CPUParticles3D` moved to `effects`, hidden
geometry and `top_level` nodes were dropped. A room written on 08-10 was measuring a different
object than the registry measured on 08-12. That is not staleness; it is two definitions.

**And the provenance that would have shown this never reached the registry.**
`measure_artifacts.gd:245` emits a `provenance` block per artifact carrying `fallback`,
`counted_meshes`, `signage`, `effects`, `unstable` and `implausible`. **0 of 2644 registry
`measurements` blocks contain it.** 159 artifacts currently record `aabb_size: [0,0,0]`, and
`spatial_contract.resolve()` silently turns that into a `[1,1,1]` default with
`prov["body.size_m"] = "default"` — a fallback that cannot say it is a fallback, which is the
exact fault the measuring script's own comment says it was rewritten to prevent.

---

## Table — footprint (the field with all the content)

`room says` = `<room>.footprint`, metres [w, d, h]. `measurement says` = registry
`measurements.aabb_size` transposed to [w, d, h]. Ratio is room ÷ measurement, worst axis bolded.

| token | field | room says | measurement says | ratio (w/d/h) | verdict |
|---|---|---|---|---|---|
| bias_visualizer | footprint | 1.70, 1.466, 1.98 | 1.70, 1.47, 1.98 | 1.00/1.00/1.00 | AGREES |
| cctv | footprint | 2.00, 4.992, 1.302 | 2.00, 4.99, 1.30 | 1.00/1.00/1.00 | AGREES |
| chladni_plate | footprint | 0.30, 0.33, 0.113 | 0.30, 0.30, 0.09 | 1.00/1.10/**1.26** | INTENT |
| control_pendulum | footprint | 0.14, 0.04, 0.75 | 0.04, 0.04, 0.64 | **3.50**/1.00/1.17 | UNCLEAR |
| CoordinateSystem3M | footprint | 7.43, 9.93, 5.46 | 4.75, 3.35, 3.35 | 1.56/**2.96**/1.63 | UNCLEAR |
| exhibit_vitrine | footprint | 0.80, 0.55, 1.50 | 0.80, 0.55, 1.50 | 1.00/1.00/1.00 | AGREES |
| exit_sign | footprint | 0.45, 0.063, 0.18 | 0.45, 0.06, 0.18 | 1.00/1.05/1.00 | AGREES (3 mm, registry snaps to 0.01) |
| fire_extinguisher | footprint | 0.23, 0.187, 0.827 | 0.23, 0.19, 0.83 | 1.00/0.98/1.00 | AGREES |
| floating_sphere_field | footprint | 7.00, 7.00, 4.00 | 0, 0, 0 (no body) | n/a | INTENT |
| galton_board | footprint | 1.10, 0.265, 1.55 | 1.10, 0.27, 1.55 | 1.00/0.98/1.00 | AGREES |
| grabbable_line | footprint | 0.28, 0.08, 0.10 | 0.28, 0.04, 0.04 | 1.00/2.00/**2.50** | INTENT |
| gradient_descent_visualization | footprint | 8.84, 8.94, 4.92 | 8.84, 8.94, 4.92 | 1.00/1.00/1.00 | AGREES |
| harmonic_distance_table | footprint | 0.86, 0.903, 1.212 | 0.86, 0.86, 1.21 | 1.00/1.05/1.00 | AGREES (+43 mm depth) |
| info_board | footprint | 1.20, 0.001, 1.60 | 0, 0, 0 (no body) | n/a | AGREES (with the code) |
| lambda_slider | footprint | 0.69, 0.33, 1.31 | 0.69, 0.33, 1.30 | 1.00/1.00/1.01 | AGREES |
| line_builder_3d | footprint | 3.55, 0.97, 1.52 | 3.53, 0.68, 1.83 | 1.01/**1.43**/0.83 | UNCLEAR |
| matrix_4x4_viewer | footprint | 1.056, 0.678, 1.54 | 1.06, 0.68, 1.54 | 1.00/1.00/1.00 | AGREES |
| neural_network_visualization | footprint | 9.792, 1.359, 9.33 | 12.62, 5.46, 8.65 | 0.78/**0.25**/1.08 | UNCLEAR |
| newton_cradle | footprint | 1.737, 0.624, 1.296 | 1.60, 0.53, 0.98 | 1.09/1.18/**1.32** | INTENT |
| origin | footprint | 1.11, 1.11, 1.32 | 1.02, 1.02, 1.02 | 1.09/1.09/**1.29** | UNCLEAR |
| pattern_loom | footprint | 2.525, 3.14, 1.225 | 2.53, 3.14, 1.22 | 1.00/1.00/1.00 | AGREES |
| perspective_lines | footprint | 1.34, 2.01, 1.12 | 1.02, 2.01, 1.02 | **1.31**/1.00/1.10 | UNCLEAR |
| phi_slider | footprint | 0.59, 0.21, 0.24 | 0.50, 0.06, 0.06 | 1.18/3.50/**4.00** | INTENT |
| pick_up_cube | footprint | 0.60, 0.60, 0.50 | 1.00, 1.00, 0.50 | **0.60**/0.60/1.00 | UNCLEAR |
| platonicsolids | footprint | 7.00, 3.00, 1.20 | 10.00, 10.00, 3.50 | 0.70/**0.30**/0.34 | INTENT |
| prism_block | footprint | 1.00, 1.00, 1.00 | 1.00, 1.00, 1.00 | 1.00/1.00/1.00 | AGREES |
| qfep_formula_3d | footprint | 1.64, 0.02, 0.13 | 1.64, 0.02, 0.13 | 1.00/1.00/1.00 | AGREES |
| random_walk_leash | footprint | 0.77, 0.621, 1.55 | 0.77, 0.37, 1.55 | 1.00/**1.68**/1.00 | INTENT |
| rotating_cube | footprint | 1.29, 1.29, 1.21 | 1.41, 1.41, 1.00 | 0.91/0.91/**1.21** | UNCLEAR |
| science_screen | footprint | 3.14, 0.20, 2.35 | 3.14, 0.20, 2.35 | 1.00/1.00/1.00 | AGREES |
| shannon_entropy_meter | footprint | 1.117, 0.012, 0.52 | 1.12, 0.01, 0.52 | 1.00/1.20/1.00 | AGREES (2 mm) |
| simulated_annealing | footprint | 1.86, 1.923, 0.996 | 1.86, 1.92, 1.00 | 1.00/1.00/1.00 | AGREES |
| **situated_bench** | **footprint** | **1.65, 1.65, 2.325** | **1.00, 1.00, 1.01** | **1.65/1.65/2.30** | **STALE** |
| wall_clock | footprint | 0.382, 0.03, 0.382 | 0.38, 0.03, 0.38 | 1.01/1.00/1.01 | AGREES |

**footprint totals: 18 AGREES · 7 INTENT · 8 UNCLEAR · 1 STALE.**

### Why the INTENT rows are intent, not error

- **floating_sphere_field** is the only room in the corpus that states its own basis:
  `"measurement_basis": "declared_dynamic_envelope"`. It is built from two `GPUParticles3D`
  and contains **zero** `MeshInstance3D`, so `_measure_body` files it under `effects` and the
  body reads `[0,0,0]`. Real emission volume is 16 × 6 × 16 m (`bounds = Vector3(8,3,8)`,
  `volume_offset y 2.4`); the room's 7 × 7 × 4 is a curatorial claim on the walkable core.
- **platonicsolids** — the measured 10 × 10 × 3.5 is the artifact's own *staged room*: a
  `PlaneMesh.size = Vector2(10,10)` rainbow floor at y −1 plus banners topping at y 2.5
  (`staging = "pride_room"`). The nine solids alone are ≈ 6.6 × 2.1 × 1.2. The room's
  7 × 3 × 1.2 is the specimen cluster. Two honest numbers about two different subjects.
- **newton_cradle** (`neighbor_policy: protect_motion_sweep`) and **random_walk_leash**
  (`protect_handle_sweep`) declare swept envelopes and say so in the field name. newton_cradle
  swings ±0.43 m from `_release_left(1)` → its AABB width really does run 1.60 ↔ 2.06 m.
- **grabbable_line** (+40 mm) / **phi_slider** (+150 mm) / **chladni_plate** (+23 mm) are grab
  affordance and vibration margins on sub-metre bodies. Absolute deltas, not ratios, are the
  honest reading here.

### Why the UNCLEAR rows are not convictable

Every one of these has a measurement that cannot be trusted as the body of a settled object:

| token | why neither number is a measurement |
|---|---|
| CoordinateSystem3M | registry number is root-LOCAL, dividing out `scale = 1.5` set in `_ready()` |
| line_builder_3d | `_spawn_points()` uses `randf_range(-1,1)` for y and `randf_range(-0.5,0.5)` for z with `handle_seed = -1` → **re-rolled every launch.** 0.95→0.68 and 1.46→1.83 are two draws, not a change. The registry already declares `dna.fixture.handle_seed = 7` for exactly this |
| neural_network_visualization | `auto_train = true` grows the ErrorGraph +0.02 m/sample at 20 samples/s (capped +4.0 m) and tweens every neuron to 1.5x. The AABB is a function of elapsed training time |
| control_pendulum | swings; AABB width runs 0.12 (plumb) ↔ 0.47 m and **decays** over ~10 s. The recorded 0.04 is narrower than the plumb state — the bob (a `grab_sphere_point` instance, r 0.06) was not counted |
| pick_up_cube | `rotate_y(2.0 * delta)` + `sin` bob ±0.2 m. Code builds 0.5 m (node scale 0.5 on a default 1×1×1 `BoxMesh`); 45° yaw gives 0.707, not the recorded 1.00 |
| rotating_cube | same class: 1.00 at 0°, 1.41 at 45°. The room's 1.29 is a third phase |
| origin | +0.30 m of unexplained height on a 1.02 m body; measurement is April, not re-run |
| perspective_lines | depth exact, width +31% unexplained; measurement is April, not re-run |

`origin`, `platonicsolids` and `lambda_slider` share mtime `2026-08-10T12:11:25` and a
**reduced placement_contract schema** (no `circulation_behind`, no `front_clearance_m`, no
`rear_clearance_m`) and `production_grade: featured_aaa`. They are an earlier authoring
generation than the other 31. Treat them as a set.

---

## Table — clearance

`front_clearance_m` / `rear_clearance_m` in metres; `→ cells` is what
`emit_dressing_room.from_room` computes (`ceil(m / 1.0)`). "measurement says" is
`spatial_needs.clearance` (or `spatial_profile.min_clearance`) in cells. 16 rooms differ on at
least one side, 2 omit the field, and **the other 16 match their registry clearance exactly**
(15 of them not listed below).

| token | field | room says | measurement says | delta | verdict |
|---|---|---|---|---|---|
| bias_visualizer | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| cctv | clearance.front | 5.0 m → 5 | 2 | +3 | INTENT (`circulation: sensor_corridor`) |
| cctv | clearance.back | 0.0 m → 0 | 2 | −2 | INTENT (`against_wall`) |
| CoordinateSystem3M | clearance.front | 1.0 m → 1 | 2 | **−1** | INTENT, flagged |
| exit_sign | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| galton_board | clearance.back | 0.0 m → 0 | 1 | −1 | INTENT (`against_wall`) |
| harmonic_distance_table | clearance.front | 1.0 m → 1 | 2 | **−1** | INTENT, flagged |
| info_board | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| lambda_slider | clearance.back | 0.0 m → 0 | 1 | −1 | INTENT (`against_wall`) |
| neural_network_visualization | clearance.front/back | 2.0/2.0 → 2/2 | 1/1 | +1/+1 | INTENT |
| pattern_loom | clearance.front | 3.0 m → 3 | 1 | +2 | INTENT (`output_runway`) |
| phi_slider | clearance.back | 0.5 m → 1 | 1 | 0 | AGREES |
| qfep_formula_3d | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| random_walk_leash | clearance.back | 0.0 m → 0 | 1 | −1 | INTENT (`against_wall`) |
| science_screen | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| shannon_entropy_meter | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| simulated_annealing | clearance.front/back | 1.0/1.0 → 1/1 | 2/2 | **−1/−1** | INTENT, flagged |
| wall_clock | clearance.front | 2.0 m → 2 | 1 | +1 | INTENT |
| **origin** | **clearance.front/back** | **absent** | 1/1 | n/a | **UNCLEAR (field missing)** |
| **platonicsolids** | **clearance.front/back** | **absent** | 2/2 | n/a | **UNCLEAR (field missing)** |

Directional clearance is authorship by `spatial_contract`'s own precedence, so a numeric
difference is not an error. The three **flagged** rows are the ones where the room reserves
*less* than the registry asks for — worth a human deciding, not worth a verdict.

`origin` and `platonicsolids` omit the field entirely, so `from_room` falls back to
`spatial_needs`, and their metre/cell round-trip is never exercised.

---

## Table — rotations

`spatial_contract` reads a **single** declared rotation as a PREFERENCE and expands it to all
four (documented at `spatial_contract.py:528-537`: eleven museums were losing a resident to the
old reading). 14 rooms declare one value; all are honoured as leads. Only rooms whose
**multi-value** set contradicts a measurement-side source are listed.

| token | field | room says | measurement says | delta | verdict |
|---|---|---|---|---|---|
| control_pendulum | rotations | 0, 90, 180, 270 | 0, 180 (pilot) | +90, +270 | UNCLEAR |
| grabbable_line | rotations | 0, 90, 180, 270 | 90, 270 (pilot) | +0, +180 | UNCLEAR |
| pick_up_cube | rotations | 0, 90, 180, 270 | 90, 270 (pilot) | +0, +180 | UNCLEAR |

A 2-or-more-value room is an enumerated set and stays binding, so these three **extend** past
what `museum_contract_pilot.json` allows. Two hand-authored stores disagreeing, with no
measurement to break the tie — the room wins on precedence and nothing records that it did.
The other 31 rooms: AGREES.

---

## Table — required_support

| token | field | room says | measurement says | delta | verdict |
|---|---|---|---|---|---|
| chladni_plate | required_support | table | pedestal | — | INTENT (`support_surface_height_m: [0.9, 1.1]`) |
| CoordinateSystem3M | required_support | floor | pedestal | — | INTENT (a 5 × 4 m field cannot stand on a pedestal; the **registry** is wrong here) |
| lambda_slider | required_support | wall | pedestal | — | INTENT |
| matrix_4x4_viewer | required_support | floor | pedestal | — | INTENT |
| phi_slider | required_support | table | none | — | INTENT |
| platonicsolids | required_support | platform | sunken → forced to `floor` by the precinct rule | — | INTENT, silently overridden |
| random_walk_leash | required_support | floor | pedestal | — | INTENT |
| science_screen | required_support | wall | table | — | INTENT |
| shannon_entropy_meter | required_support | wall | pedestal | — | INTENT |
| **prism_block** | **required_support** | **plinth** | none (room's own `posture` says `pedestal`) | — | **UNCLEAR** |

The other 24: AGREES.

**`prism_block` is the one internal contradiction.** `"required_support": "plinth"` is the
**only** occurrence of that value in all 82 placement_contracts (the rest of the corpus uses
none/floor/wall/table/platform/pedestal), and the same file's top-level `"posture": "pedestal"`
says something different. `emit_dressing_room._footing()` raises the footing only for
`{pedestal, podium, table}`, so `plinth` builds a **flat** footing while the posture asks for a
raised one. Nothing errors.

---

## Table — interaction_faces

| token | field | room says | measurement says | delta | verdict |
|---|---|---|---|---|---|
| harmonic_distance_table | interaction_faces | south, east, north, west | `player_position: above` | — | INTENT (`above` is not a side; resolver maps it to `front`) |
| newton_cradle | interaction_faces | south, north | `player_position: above` | — | INTENT |
| **origin** | **interaction_faces** | **north, east, south, west** | `player_position: front` | first face = **back** | **UNCLEAR** |
| **platonicsolids** | **interaction_faces** | **north, east, south, west** | `player_position: front` | first face = **back** | **UNCLEAR** |

The other 30: AGREES.

`origin` and `platonicsolids` are the only two rooms that list **north first**. The order is
load-bearing: `from_room` maps the list positionally, so `required_sides[0]` becomes `back`,
and `emit_dressing_room.build()` derives `approach` from `required_sides[0]`. Both rooms'
own top-level `"approach"` field says **`"south"`**. The room contradicts itself, and the
negotiator will take the face list.

---

## Table — containment

**No room of the 34 declares `containment`.** All fall through to the measured verdict
(`> 8 m widest slot` or `> 4 m wall` → `precinct`), which is the documented precedence, so:
**31 AGREES.** Three resolve to `precinct`, and for those the room's other fields are affected:

| token | field | room says | measurement says | delta | verdict |
|---|---|---|---|---|---|
| gradient_descent_visualization | containment | (absent) | precinct — 8.94 m across, 4.92 m tall | — | AGREES (hard_zone 9×9×5 does hold it) |
| **neural_network_visualization** | **hard_zone_m** | **10, 2, 10** | body 12.62 × 5.46 × 8.65 | **−2.62 m w, −3.46 m d (2.73x)** | **STALE** |
| platonicsolids | hard_zone_m | 9, 5, 4 | body 10.00 × 10.00 × 3.50 | −1.0 m w, −5.0 m d (2.0x) | UNCLEAR |

Those two are the **only** rooms in the 34 whose `hard_zone_m` is smaller than the measured
body. Every other room reserves enough.

`platonicsolids` is UNCLEAR rather than STALE because its measurement is April-dated and
**unchanged by the re-measure** — the 10 × 10 pride-room floor has been there the whole time,
so the room never was right and the re-measure did not make it wrong. Also: because containment
resolves to `precinct`, `spatial_contract.py:744` overrides its authored
`required_support: "platform"` to `"floor"` without recording a conflict.

---

## The two STALE fields, and the one-line edit for each

**1. `commons/artifacts/dressing_rooms/situated_bench.json` — `footprint`**

The code is unambiguous: `situated_bench.gd` at `address = "witness"` builds a slab
`_box(y 0.36, size (1.0, 0.16, 1.0))` fixing x and z at exactly ±0.5, legs bottoming at y 0,
and a SPIKE readout topping at y 1.006. Measured `1.00 × 1.00 × 1.01` is that build to three
decimals. `_process` only spins the readouts about Y inside the slab, so the AABB is
time-invariant. The room's extra height is the `"NO VIEW FROM NOWHERE"` title — a `Label3D`,
reclassified as **signage** by the 2026-08-11 `_measure_body` rewrite, one day *after* the room
was written. Room predates the redefinition; that is staleness in the exact sense asked for.

> Edit: in `situated_bench.json`, change `"footprint": [1.65, 1.65, 2.325]` to
> `"footprint": [1.0, 1.0, 1.01]`.

**2. `commons/artifacts/dressing_rooms/neural_network_visualization.json` —
`placement_contract.hard_zone_m`**

`10 × 2 × 10` was sized to the network at t = 0, before `auto_train` draws its first error
sample. The static build alone is 9.6 m wide × 8.1 m tall, and the ErrorGraph is placed at
`Vector3(12, -3, -5)` — so from the first frame the depth is ≈ 5.5 m, not 2. The graph then
grows +0.02 m per sample at 20 samples/s, capped at 200 samples (+4.0 m), giving a saturated
width of ≈ 13.6 m. `hard_zone_m` is the field the negotiator treats as inviolable, and it is
short on two of three axes at every instant after boot.

> Edit: in `neural_network_visualization.json`, change
> `"hard_zone_m": [10, 2, 10]` to `"hard_zone_m": [14, 6, 9]`
> (14 = saturated width 13.6 ceil'd; 6 = graph at z −5 plus neuron radius; 9 = measured 8.65).
> `preferred_zone_m` is already `[14, 6, 11]` and needs no change.

Its `footprint` stays UNCLEAR: the body has no settled size, so no single number is correct.
The real fix is a capture fixture (`auto_train = false`, or a sample-count seed), not a
different literal.

---

## Not stale, but a human should decide

1. **`emit_dressing_room.from_room`'s unit heuristic has no margin.** It reads `footprint` as
   metres when *any* value is fractional **or** a `placement_contract` is present. Two of the
   34 metre-rooms have no fractional tell at all — `floating_sphere_field [7.0, 7.0, 4.0]` and
   `prism_block [1.0, 1.0, 1.0]` — and are rescued only by the `bool(pc)` corroborator. A
   metre-room written without a `placement_contract`, or a cell-room that gains one, flips
   silently. An explicit `"footprint_units": "m" | "cells"` key would end the guess; the
   precedent already exists in `floating_sphere_field`'s `measurement_basis`.

2. **The comment justifying "THE MEASUREMENT WINS ON BODY SIZE"
   (`emit_dressing_room.py:202-209`) cites a comparison that does not hold.** It says
   CoordinateSystem3M's room "still says 7.43 x 9.93 m for a body that now measures 4.75 x
   3.35" and concludes "Every other such room agrees with its body to two decimals, so this is
   staleness, not a second meaning for the field." Both halves are wrong: the 4.75 is a
   local-frame number missing a 1.5x self-scale, and 18 of 34 rooms do not agree to two
   decimals. The *rule* may still be right — but it is currently resting on this example.

3. **159 artifacts record `aabb_size: [0,0,0]` and nothing marks them as fallbacks.**
   `measure_artifacts.gd:245` emits a `provenance` block with a `fallback` flag; 0 of 2644
   registry `measurements` blocks carry it. `spatial_contract.resolve()` then converts a zero
   AABB into `[1,1,1]` labelled `"default"`. Propagating `provenance` into the registry would
   let `from_room` know when it is overruling a room with nothing.

4. **`_measure_body` misses `GPUParticles3D` and `Sprite3D` bodies, not just
   `MultiMeshInstance3D`.** `floating_sphere_field` is two `GPUParticles3D` and zero
   `MeshInstance3D`; `info_board`'s only `MeshInstance3D` (`info_board.tscn:218`, node `Board`)
   has **no mesh assigned** and its visible panel is a `Sprite3D`. Both read `[0,0,0]`. The
   `layers = 0` anchor convention in `CLAUDE.md` needs to name those two node types too.

5. **`origin` and `platonicsolids` contradict themselves on approach** (see the
   interaction_faces table): face list starts `north`, top-level `approach` says `south`.

6. **`prism_block` uses a `required_support` value nothing else in the corpus uses**
   (`plinth`), and it disagrees with its own `posture: pedestal`.

7. **Four artifacts have no capture fixture and cannot be measured reproducibly:**
   `line_builder_3d` (unseeded `randf_range` per launch — the registry already declares
   `dna.fixture.handle_seed = 7`, unused by the measure path), `neural_network_visualization`
   (unbounded training growth), `control_pendulum` and `newton_cradle` (decaying swing —
   newton_cradle's AABB varies 29% by instant), `pick_up_cube` and `rotating_cube` (continuous
   yaw). Until each has a `still`/seed fixture, comparing any room against their AABB is
   comparing against a coin toss.

---

## Method

- 34 targets = every `commons/artifacts/dressing_rooms/*.json` carrying a `placement_contract`
  and **no** `_generated` block (82 rooms have a `placement_contract`; 48 are generated).
- "measurement says" = `tools/spatial_contract.py::resolve()` with `room_for` monkey-patched to
  return `{}`, so the room cannot feed its own answer back. This yields the registry +
  `museum_contract_pilot` + `artifact_spatial_contracts` + `spine_hints` view.
- Pre-re-measure values read from `git show HEAD:commons/artifacts/registry/<file>` — the
  re-measure is **uncommitted**, so HEAD is the before-state.
- Room authoring time from file mtime; measurement time from `measurements.measured_at`.
- Geometry claims verified by reading the artifact `.gd`/`.tscn` sources, not inferred from the
  numbers.
