# Centred blades and an angle gradient

## Blade crossings

Source: `commons/artifacts/rotation_studies/wall_crossings.gd`.

All three panels have their local centre at `Vector3.ZERO` under a pivot. Each measures 8.4 by 2.4 by 0.2 metres. Mesh and physical box share the pivot.

| Station | Axis and signed crossing angle | Source-grid route |
| --- | --- | --- |
| Y | +y, +90 degrees | Ground to ground along z |
| X | +x, -23.19859 degrees | Ground to +3 m along z |
| Z | +z, +23.19859 degrees | Ground to +3 m along x |

The gap between the bank faces is 7 m and the rise is 3 m. The climb angle is `atan(3/7)`. The X/Z axle height is `3/2 - 0.2/(2*cos(angle))`, approximately 1.3912 m. This accounts for panel thickness: the upper plane meets y=0 and y=3 at the two bank faces. The longer blade overlaps the banks.

```gdscript
station.pivot.basis = Basis(station.axis,deg_to_rad(degrees*float(station.sign)))
```

Each pivot sits at the panel's middle, unlike the previous bottom-hinged prototype. The source map supplies all static landing geometry; the artifact builds no bank slabs. Grid height 1 has its top at world y=0, height 4 at y=3. A four-metre basin gives the larger paddle sweep room below the deck.

The running score holds each crossing pose for twelve seconds and advances a half-turn at fifteen degrees per second, also twelve seconds. It repeats in the reversed sense, lowering the raised end of X/Z as it leaves the climb pose. A centred rectangular blade has the same collision geometry after half a turn. The probe can select `set_crossing_pose()` without depending on frame timing.

## Array gradient

Source: `commons/artifacts/rotation_studies/array_compare.gd`.

Each of four bands has four columns and ten rows. A cube edge is 2.04 m; centre spacing is 2 m. The small overlap makes the zero-degree control continuous. Centres stay fixed at y=-1.02, giving a flat top at y=0 before rotation. Array rows occupy z=33 through 52 in the source map; the structure cells beneath them are empty.

```gdscript
var degrees := float(cube.get_meta("row"))*row_angle_step
cube.basis = rotation_for_band(band,degrees)
```

The default `row_angle_step` is ten degrees: rows 0 through 9 receive 0 through 90. X uses a negative turn, Y and Z a positive turn. XYZ applies those same signed turns in fixed order, X then Y then Z: `Basis(z,a) * Basis(y,a) * Basis(x,-a)`. This band composes three rotations; it does not compare alternative composition orders. This is a static spatial score, not an animation of the whole floor or a shared-parent array turn. The four array bands compare the same dimensions, spacing and angle magnitudes around different axes.

Each physical box inherits its cube's basis. One additional line mesh per band draws the edges of its forty cubes; those lines have no collision. `apply_gradient()` refreshes transforms, outlines and row labels when the exported angle step is changed by tooling.

## Evidence and limits

`commons/testing/probe_rotation_studies.gd` loads the actual GridSystem. The capsule is 0.22 m in radius, 1.6 m high, with a 45-degree floor limit, moving at 2 m/s without jumping. It checks all three blade crossings, zero-angle array controls, the gradient routes, fixed centres, matching collision and unchanged surrounding grid transforms.

The X and Z blades reach y=3. The Y blade reaches y=0. All flat array controls cross. With the ten-degree row increment, the straight-walking capsule stalls after about 9.22 m in XYZ, 10.90 m in X and 12.71 m in Z. Y completes the 23 m route. All four zero-angle controls complete it. These are measured paths, not proofs against jumping or lateral detours. The probe distinguishes an actual stall from exhausting its time allowance and permits normal height changes across the rough surface.

The report is `ada_run/rotation_studies_checks.json`. A straight capsule walk does not establish an absolute traversal limit for the actual player: jumping, turning, choosing another column and VR movement remain useful experiments. Static crossing poses are tested; live timing and moving-platform riding require a human walk.

`probe_rotation_turn_direction.gd` adds nine checks: each centre stays fixed, X/Z raised ends descend when leaving the hold, Y swings in the reversed sense, and the next half-turn restores the same physical crossing bounds.
