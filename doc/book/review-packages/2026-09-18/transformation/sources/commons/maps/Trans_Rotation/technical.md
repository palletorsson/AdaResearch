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

This hall configures each of four bands with two columns and six rows. The artifact defaults remain four columns and ten rows for other placements. A cube edge is 2.04 m; centre spacing is 2 m. The small overlap makes the zero-degree control continuous. Centres stay fixed at y=-1.02, giving a flat top at y=0 before rotation. Array rows occupy z=25 through 36 in the source map; the structure cells beneath them are empty.

```gdscript
var degrees := float(cube.get_meta("row"))*row_angle_step
cube.basis = rotation_for_band(band,degrees)
```

The hall sets `row_angle_step` to eighteen degrees: rows 0 through 5 receive 0, 18, 36, 54, 72 and 90. The default outside this hall remains ten degrees. X uses a negative turn, Y and Z a positive turn. XYZ applies those same signed turns in fixed order, X then Y then Z: `Basis(z,a) * Basis(y,a) * Basis(x,-a)`. This band composes three rotations; it does not compare alternative composition orders. This is a static spatial score, not an animation of the whole floor or a shared-parent array turn. The four array bands compare the same dimensions, spacing and angle magnitudes around different axes.

Each physical box inherits its cube's basis. One additional line mesh per band draws the edges of its twelve cubes; those lines have no collision. `apply_gradient()` refreshes transforms, outlines and row labels when the exported angle step is changed by tooling.

## Spatial repetition and angular rate

The tunnel uses five full-size hollow cubes at 3 m spacing. Each shell is 3 m deep, making a 15 m visible run. The invisible framing anchor extends a further metre. `rotation_per_segment=18` gives angles 0–72 degrees. `segment_vertical_offset=-0.65` retains the clear standing passage used by the earlier gallery.

Five carousel profiles remain: cake, column, ziggurat, spindle and flare. Every placement uses `gallery:clean`, which removes a saved duplicate and makes collision follow the drawn radii. The uniform placement scale is 0.4; neither the speed rule nor the ratios change. Eight layers turn at `0.5 * pow(1.2, i)` radians per second. A rim point's speed is its world radius times angular speed.

## Evidence and limits

`commons/testing/probe_rotation_compact.gd` loads the current actual source grid. It measures the full-size blade crossings, shorter array controls, changed angle gradient, still side aisle and body clearance through the tunnel. Results belong to a 0.22 m radius, 1.6 m capsule walking without jumping. They do not establish a universal traversal limit or headset comfort.

On the compact gradient, the straight-walking probe stops after 6.90 m in X, 4.66 m in Z and 5.22 m in XYZ; Y completes the 14 m test. All four zero-angle controls complete it. The shorter, eighteen-degree sampling changes the comparison with the older ten-degree array. The route is a result of specific spacing, samples and body settings, rather than a ranking inherent in the axis names.

The earlier 4 by 10 array measurements remain historical evidence in `ada_run/rotation_studies_checks.json`; their coordinates and distances do not describe this compact layout. The before source is preserved in `doc/space/transformation-refresh-2026-09-16/before`.

`probe_rotation_turn_direction.gd` remains applicable to the unchanged blade artifact: each centre stays fixed, X/Z raised ends descend after the hold, Y swings in the reversed sense, and a half-turn restores the same crossing bounds.
