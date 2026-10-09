# Compact rotation hall

Two halls are now one 39 × 60 map: 2,340 source cells instead of 5,095 across the old 51 × 60 and 37 × 55 maps (54.1% smaller).

1. Three full-size 8.4 m centre blades retain Y level crossing and X/Z climbs. Two grid-wedge runs return from the raised banks.
2. Four two-column, six-row arrays retain 2.04 m cubes and 2 m centre spacing. Eighteen-degree row steps reach ninety in six samples. These compare X, Y, Z and the fixed composition X-then-Y-then-Z.
3. A full-size five-segment tunnel carries the same eighteen-degree spatial increment into an enclosure. Five 0.4-scale carousel profiles retain every distinct earlier silhouette and the original angular-speed rule. One identical extra cake was omitted.

The book anchors now follow those four artifact IDs, and local tutorial/technical/critical/summary/intent text matches the merged map. The old Spectacle folder is untouched and both maps were snapshotted before work.

## Validation

`commons/testing/probe_rotation_compact.gd`: 42 checks, zero failures, no GDScript errors. Actual source-grid geometry is instantiated. All three held blade crossings, four unrotated arrays, two descending wedge returns, a standing-capsule sweep through the tunnel, and two continuous side aisles pass.

Gradient observations for the same straight-walking capsule: X stops at 6.90 m, Z at 4.66 m, XYZ at 5.22 m; Y completes 14 m. These measure one movement rule, not every possible route or headset comfort.

A shared parsing defect was exposed by the merge: numeric tunnel/array staging keys were read as tutorial yaw shorthand. Six documented configuration keys were added to `GridInteractablesComponent.CONFIG_PARAM_NAMES`. Regression assertions preserve their values and authored yaw, while preserving genuine tutorial shorthand.

## Actual museum images

The separate `ada_run/rotation_compact_museum_capture.gd` loads the real endless-museum scene, selects Trans_Rotation, builds its actual embedded grid and captures the staged room. It records loaded dimensions and token/config checks in `rotation-museum-capture.json`. The images show current museum geometry; they are not image-generation mockups.

- `rotation-museum-overview.png`
- `rotation-museum-blades.png`
- `rotation-museum-arrays.png`
- `rotation-museum-gallery.png`
- `rotation-museum-eye-level.png`

Source-grid diagnostic images are retained separately as `rotation-compact-*.png`. Ordinary preexisting UID/certificate/GL-cache warnings remain in logs. Headset use and live crossing comfort are unverified.
