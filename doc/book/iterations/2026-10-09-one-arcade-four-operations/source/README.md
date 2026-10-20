# One arcade, four operations

Open `res://commons/artifacts/architecture_variations/preview.tscn` in the existing Ada project and press F6. This is a separate research courtyard using the museum's desktop player and interaction controls. The main museum spine is unchanged.

Walk with the existing desktop controls. Aim and click the rectangular preset buttons; drag the dials. Keys 1–5 select Source, Curve, Hinge, Field, Stretch. Left/right change strength; up/down change the bay count; R restores the source preset. The pink point has desktop pointer-drag and XRTools grip support. In Hinge, its height chooses the shared joint centre; in Stretch, its position changes the roof pull. XR code is tested with supplied controller poses, not a physical headset. The standalone preview spawns the desktop player, not an XR rig.

The source bay is constructed by `architecture_spine.gd`'s existing `build_bay()`. Its material-grouped box geometry is sampled more densely before deformation. A fixed eight-bay miniature remains on the plinth. The study copies floor, columns, roof, rails and pink guide; labels are not baked into the model.

| Study | Operation | What remains |
|---|---|---|
| Source | Repeat the original bay | Twelve bays, all upright |
| Curve | Map the longitudinal coordinate onto a circular arc | Height, surface connectivity, recognizable parts; circumferential lengths vary across the width |
| Hinge | Compose rigid transforms around a chosen centre | Each bay's dimensions and hinge coincidence; floors can separate, roofs can intersect |
| Field | Repeat bays into rows and tiers | One shared mesh; the preset is 18 × 3 × 2 = 108 bays, not infinity |
| Stretch | Apply a bounded, height-weighted displacement to sampled vertices | Ground points and triangle count; upper columns and roofs stretch |

This is a visual study, not a structural or soft-body simulation. The changing architecture has no colliders. The fixed courtyard supplies walking support; passing through an apparent wall is possible. No traversable folded route or gravity reversal is claimed. Some extreme hinge settings put parts below the ground or through one another; those are visible consequences, not collision responses.

Parameters are bounded: 4–24 bays, strength 0–1, grab displacement x/z ±0.4 m and y −0.4…0.5 m. Geometry rebuilds only on change, at most 12 Hz while dragging. Field uses shared geometry. No Quest frame-time claim.

Validation: `python tools/test_architecture_variations.py`. Runs Godot 4.6 on the local configured executable, captures native views, checks mathematical invariants, immutable source, reset, actual desktop buttons, supplied XRTools grip/move/release, and exports six GLBs. Expected 35 checks. Existing project startup UID/Jolt warnings remain in the log.

The web viewer rotates the actual exported Godot states. Parameter editing happens in Godot; the browser does not run a second version of the geometry algorithm.
