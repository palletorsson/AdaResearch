# Root scale was divided out of every recorded AABB

`commons/testing/measure_artifacts.gd` ended `_measure_body()` with

```gdscript
return root.global_transform.affine_inverse() * body
```

which expresses the body in the ROOT's own space. An artifact that sets its own root scale in
`_ready()` therefore had that scale divided straight back out of the number the registry keeps.
`CoordinateSystem3M.gd:37` sets `scale = Vector3(1.5, 1.5, 1.5)`; the registry ships
`4.75 x 3.35 x 3.35` and the body is `7.13 x 5.02 x 5.02`.

This is upstream of footprints, plinth lifts, slot capacity and the 2D→3D correspondence gate,
all of which reason in world metres — `GridSystem.cube_size` is `1.0`, so one grid cell is one
world metre, and `sync_footprints.py` ceils `grid_cells` straight into
`spatial_needs.footprint_cells`.

---

## The prediction (written before any measurement)

**Predicted: 34.** Of the ~60 `.gd` files that assign to their own `scale`, I predicted 34 would
be genuinely mis-measured registered artifacts — root script of a registered `.tscn`, assignment
runs before the box is read, value not `Vector3.ONE`. The 60 were guessed to decompose into ~6
`Vector3.ONE` no-op resets, ~8 assignments in grab/hover/pulse handlers that never run headless,
~3 false positives where `scale` is a local `float` or an array of musical notes, ~9 scripts
either not the root of their scene or not registered, leaving ~34 live.

**Measured: 37.** Prediction was 9% low. Where the reasoning went wrong is more interesting than
the miss: I over-counted the "never runs headless" bucket. The measurement loop gives every
artifact two process frames plus a 0.35 s settle *before* freezing it, so `_process` animations
do run and do set root scale. It also under-counted the pool: `algorithms/physicssimulation/*`
alone contributes 14 artifacts all at `Vector3(0.8, 0.8, 0.8)` in `_ready()`.

The opposite error also showed up. I assumed `apply_grid_config` assignments would count; they do
not, because the measurement instantiates the packed scene and never calls it. Twelve artifacts
set root scale *only* in `apply_grid_config` and so measure at `ONE` here — but are scaled in a
real map. That is a separate, still-open discrepancy, noted at the bottom.

## Blast radius

Derived by joining 2653 registry entries carrying a `scene` against each `.tscn`'s root script
and that script's full `extends` chain, then measuring all of them in Godot with the root
transform recorded in provenance.

| | count |
|---|---|
| registered artifacts whose root script (or a base) assigns to its own `scale` | 83 |
| of those, root scale `!= ONE` at measure time | 39 |
| — with no visible body at all, box is `0 x 0 x 0` either way (`particle_systems`, `soft_bodies`) | 2 |
| **— genuinely mis-measured** | **37** |
| registered artifacts whose recorded box the fix does NOT move | 46 |

Scale factor distribution across the 37:

| factor | n | who |
|---|---|---|
| **x0.5** | 17 | the `algorithms/vectors/*` family and the artifacts extending `vector_scene_base.gd` |
| **x0.8** | 14 | almost all of `algorithms/physicssimulation/*` |
| **x3.2** | 1 | `xyz_coordinates` |
| **x1.5** | 1 | `CoordinateSystem3M` |
| **x1.3** | 1 | `modernchair` |
| **x1.0452** | 1 | `spherecolors` — animation phase, see caveat |
| **x1.0084 / 0.979 / 1** | 1 | `tensegrity_triangle` — animation phase, see caveat |
| **x0.74** | 1 | `armadillo_eggling` |

Two clusters carry 31 of the 37. Both are systematic: a whole domain shrinks itself by a constant
in `_ready()` and the whole domain was recorded at the wrong size.

## The fix: world extents, not root-local plus a stored factor

Argued from consumption. Grid cells are world metres, and no consumer multiplies by anything —
`sync_footprints.py` ceils `grid_cells` directly, `fit_plinth_caps.py`, `place_artifacts.py`,
`walk_evaluator.py` and ~40 others read the metres as given. Recording root-local and storing the
factor beside it would require every one of those to learn a new field, and would leave the
current wrong number in place for any that never did. Decisive detail:
`GridInteractablesComponent.gd:1080` applies a map token's scale as

```gdscript
artifact_object.scale *= scale_factor
```

— **multiplicative**. The artifact's own root scale is therefore present in the world body of
every placement; a token override composes with it rather than replacing it. The scale is set in
the artifact's own code, which makes it as intrinsic as its mesh sizes. It belongs in the number.

**But only the scale.** Measuring the full world transform first, and reading the result, killed
that version:

- `edible_mushroom` and the three grab cubes recorded centres at y ≈ −1.5 m. `XRToolsPickable`
  extends `RigidBody3D`, and `_disable_processing_recursive` stops `_process`/`_physics_process`
  callbacks but not the physics server — so they **fall** for the 0.5 s of settle. ½·g·0.55² ≈ 1.5 m.
- `ruth_asawa_sculpture` recorded a root yaw of −146.65°, from `rotation.y += rotation_speed * delta`.
  `three_body_problem` recorded a tumble of 6.85°/1.83°.

Those are functions of when you looked, not properties of the artifact; a registry written from
them would not reproduce between runs. Root **scale** is authored, static and reproducible. So the
recording frame is now *rigidly pinned to the artifact's origin, carrying the artifact's scale*:

```gdscript
var ref_inv := Transform3D(root_xform.basis.orthonormalized(), root_xform.origin).affine_inverse()
...
var world: AABB = ref_inv * (vi.global_transform * local)
```

Removing the rigid part **per mesh** instead of on the merged box fixes a second fault of the old
line for free: un-rotating an already-axis-aligned box can only grow it, so every artifact with a
self-rotation was over-reported. `ruth_asawa_sculpture` measured 7.67 m wide that way against a
true 5.54 m.

Provenance now carries `root_scale`, `root_scale_applied`, the exact old `root_local_size`, and
`root_position_unapplied` / `root_rotation_deg_unapplied`, so the change is auditable from the
output data alone.

### Checks

- Compile: `check_compile.gd` → `1 checked, 0 failed`.
- Arithmetic: `after == before x scale` holds for **37 of 37**.
- **Regression: of the 46 artifacts measuring at scale `ONE`, 0 moved by more than the 0.01
  snap.** The fix is a strict no-op for every artifact that does not scale its own root.

## Before / after

83 named artifacts re-measured; nothing written to the registry. `!` marks a running simulation
whose box differs slightly between runs regardless of this fix.

| lookup_name | registry | scale | before (w x h x d) | after (w x h x d) | cell area | shipped `footprint_cells` |
|---|---|---|---|---|---|---|
| `VectorAddition` | vectors | x0.5 | 1.36 x 1.02 x 0.82 | 0.68 x 0.51 x 0.41 | 2 → 1 | **2 → 1** |
| `VectorBasics` | vectors | x0.5 | 1.48 x 1.62 x 0.82 | 0.74 x 0.81 x 0.41 | 2 → 1 | **2 → 1** |
| `VectorCrossProduct` | vectors | x0.5 | 1.27 x 1.45 x 1.09 | 0.63 x 0.73 x 0.55 | 4 → 1 | **2 → 1** |
| `VectorDotProduct` | vectors | x0.5 | 1.01 x 1.02 x 0.76 | 0.50 x 0.51 x 0.38 | 2 → 1 | **2 → 1** |
| `VectorFieldFlow` | vectors | x0.5 | 3.54 x 1.59 x 3.54 | 1.77 x 0.80 x 1.77 | 16 → 4 | **8 → 4** |
| `VectorForces` | vectors | x0.5 | 1.61 x 3.29 x 0.82 | 0.80 x 1.65 x 0.41 | 2 → 1 | **2 → 1** |
| `VectorProjectionReflection` | vectors | x0.5 | 1.98 x 1.43 x 1.85 | 0.99 x 0.72 x 0.93 | 4 → 1 | **4 → 1** |
| `VectorSubtraction` | vectors | x0.5 | 1.42 x 1.36 x 0.96 | 0.71 x 0.68 x 0.48 | 2 → 1 | **2 → 1** |
| `armadillo_eggling` | hazards | x0.74 | 1.07 x 0.86 x 1.08 | 0.79 x 0.64 x 0.80 | 4 → 1 | **4 → 1** |
| `fem_simulation` | physics_simulation | x0.8 | 0.60 x 0.60 x 0.60 | 0.48 x 0.48 x 0.48 | 1 → 1 | **4 → 1** |
| `magnetic_simulation` | physics_simulation | x0.8 | 2.82 x 0.62 x 2.38 | 2.25 x 0.50 x 1.91 | 9 → 6 | **9 → 6** |
| `modernchair` | primitives | x1.3 | 0.25 x 0.25 x 0.90 | 0.32 x 0.32 x 1.17 | 1 → 2 | **1 → 2** |
| `numerical_integration` ! | physics_simulation | x0.8 | 2.25 x 1.64 x 0.38 | 1.80 x 1.31 x 0.30 | 3 → 2 | **1 → 2** |
| `steppedpyramid` | primitives | x0.5 | 4.00 x 4.00 x 1.00 | 2.00 x 2.00 x 0.50 | 4 → 2 | **1 → 2** |
| `three_body_problem` ! | physics_simulation | x0.8 | 202.36 x 241.55 x 258.93 | 161.89 x 193.24 x 207.15 | 52577 → 33696 | **1 → 9** |
| `vector_arena` ! | vector_arena | x0.5 | 2.31 x 3.33 x 1.47 | 1.16 x 1.67 x 0.73 | 6 → 2 | **8 → 2** |
| `xyz_coordinates` | commons_artifacts | x3.2 | 1.32 x 1.32 x 1.32 | 4.22 x 4.22 x 4.22 | 4 → 25 | **4 → 9** |
| `CoordinateSystem3M` | vectors | x1.5 | 4.75 x 3.35 x 3.35 | 7.13 x 5.02 x 5.02 | 20 → 48 | 9 (capped, same) |
| `VectorMotion` | vectors | x0.5 | 0.97 x 6.50 x 0.82 | 0.49 x 3.25 x 0.41 | 1 → 1 | 1 (same) |
| `VectorTorque` | vectors | x0.5 | 0.95 x 1.46 x 0.92 | 0.48 x 0.73 x 0.46 | 1 → 1 | 1 (same) |
| `adder_board` | adder_board | x0.5 | 1.66 x 1.29 x 1.25 | 0.83 x 0.64 x 0.63 | 4 → 1 | none set |
| `agreement_gauge` | agreement_gauge | x0.5 | 0.90 x 1.43 x 0.67 | 0.45 x 0.71 x 0.34 | 1 → 1 | none set |
| `bouncing_ball` ! | physics_simulation | x0.8 | 8.06 x 7.80 x 8.06 | 6.45 x 6.24 x 6.45 | 81 → 49 | 9 (capped, same) |
| `cloth_simulation` | soft_bodies | x0.8 | 7.30 x 2.13 x 4.36 | 5.84 x 1.70 x 3.49 | 40 → 24 | 9 (capped, same) |
| `collision_detection` ! | physics_simulation | x0.8 | 5.07 x 4.73 x 2.88 | 4.05 x 3.78 x 2.30 | 18 → 15 | 9 (capped, same) |
| `constraints` ! | physics_simulation | x0.8 | 10.38 x 20.85 x 8.08 | 8.30 x 16.68 x 6.46 | 99 → 63 | 9 (capped, same) |
| `fluid_simulation` | physics_simulation | x0.8 | 15.10 x 4.22 x 15.10 | 12.08 x 3.38 x 12.08 | 256 → 169 | 9 (capped, same) |
| `force_fields` ! | physics_simulation | x0.8 | 8.58 x 4.39 x 3.60 | 6.87 x 3.51 x 2.88 | 36 → 21 | 9 (capped, same) |
| `length_lantern` | length_lantern | x0.5 | 1.63 x 1.33 x 1.32 | 0.81 x 0.66 x 0.66 | 4 → 1 | none set |
| `mass_spring_damper` | physics_simulation | x0.8 | 5.99 x 5.30 x 2.42 | 4.79 x 4.24 x 1.94 | 18 → 10 | 9 (capped, same) |
| `rigid_body` | physics_simulation | x0.8 | 20.20 x 5.00 x 20.20 | 16.16 x 4.00 x 16.16 | 441 → 289 | 9 (capped, same) |
| `spherecolors` | color | x1.0452 | 3.89 x 3.05 x 3.89 | 4.07 x 3.19 x 4.07 | 16 → 25 | 9 (capped, same) |
| `spring_mass_system` | physics_simulation | x0.8 | 7.52 x 4.32 x 7.52 | 6.02 x 3.46 x 6.02 | 64 → 49 | 9 (capped, same) |
| `stretch_bench` | stretch_bench | x0.5 | 1.04 x 1.15 x 0.54 | 0.52 x 0.57 x 0.27 | 2 → 1 | none set |
| `tensegrity_triangle` | primitives | x1.0084/0.979/1 | 1.35 x 1.25 x 0.15 | 1.36 x 1.22 x 0.15 | 2 → 2 | none set |
| `vector_fields` | physics_simulation | x0.8 | 3.50 x 3.97 x 3.24 | 2.80 x 3.18 x 2.59 | 16 → 9 | 9 (capped, same) |
| `weather_vector_field` | vectors_demos | x0.5 | 12.37 x 5.90 x 11.00 | 6.18 x 2.95 x 5.50 | 143 → 42 | 9 (capped, same) |

### Which would change placement outcome

**17 of 37** would move their shipped `spatial_needs.footprint_cells` if `sync_footprints.py`
were re-run — the first 17 rows above. The rest are protected by the cap: `FOOTPRINT_CAP = 9`
absorbs anything over a 3x3, so the whole `physicssimulation` cluster stays at 9 despite
`rigid_body` dropping from 441 to 289 raw cells. The cap is hiding a systematic 0.8x error rather
than the error being harmless.

Sharpest individual cases:

- **`xyz_coordinates`** is the worst. Shipped `1.32³` with `footprint_source: "measured"`; the
  body is `4.22³`. Every axis under-reported by 3.2x, footprint 4 → 25 raw cells (9 capped). This
  artifact is planned for as a desk object and stands in maps as a room feature.
- **`vector_arena`** and **`VectorFieldFlow`** go the other way: reserved at 8 cells, actually
  need 2 and 4. Space is being held for bodies half the size.
- **`modernchair`**, **`steppedpyramid`**, **`numerical_integration`** all grow past their
  shipped value — these are the ones that can produce a body that does not fit its slot, which is
  the failure mode `tools/verify_placement.py` would report as a fault in the plan.
- **`CoordinateSystem3M`**, the artifact that surfaced this, keeps `footprint_cells: 9` because
  it was already capped — but its `measured_footprint_cells` is 20 against a true 48.

## Caveats and what is still open

1. **Two of the 37 have an animation-phase factor, not an authored one.** `spherecolors`
   (`scale = Vector3.ONE * pulse`) and `tensegrity_triangle` (`Vector3(1 + load*0.4, 1 - load, 1)`)
   read 1.0452 and 1.0084/0.979/1 this run, 1.0418 and 1.0084/0.9791/1 the previous run. The fix
   makes their numbers *more* correct but not reproducible. They need the seeded-export / fixture
   remedy the DNA work uses, not a measurement change.
2. **Self-rotation is still divided out**, deliberately (see above). This costs nothing today:
   the six affected artifacts are the five line puzzles at a static 90° yaw — where 0.27 m and
   1.00 m both ceil to one cell, so the footprint is 1x1 either way — plus the spinning
   `ruth_asawa_sculpture`. If a future artifact authors a static, non-square, non-90° self-rotation
   this becomes wrong and should be revisited.
3. **Twelve artifacts scale their root only in `apply_grid_config`**, which the measurement loop
   never calls. They measure at `ONE` here and are scaled in a real map. Not this bug, not fixed
   by this change, and worth its own pass.
4. **`three_body_problem` at 202 m is a runaway simulation**, already caught by the existing
   `oversize`/`unstable` flags. Its shipped `footprint_cells: 1` is wrong for that separate reason.
5. **Nothing was written to the registry.** The 83 measurements live in
   `user://root_scale_probe/artifact_measurements.json`
   (`%APPDATA%/Godot/app_userdata/Ada Research Zero One/root_scale_probe/`). Applying them means
   re-running `tools/measure_artifact_aabbs.py` and then `tools/sync_footprints.py --apply`, and
   that is a decision for a human — 17 live `footprint_cells` move, and `sync_footprints` writes
   into 124 tab-indented registry files.
