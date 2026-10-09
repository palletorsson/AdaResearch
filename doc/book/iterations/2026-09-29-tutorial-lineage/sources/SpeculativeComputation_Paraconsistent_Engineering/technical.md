# Keep the conflict — implementation and encounter

The primary artifact is `merge_conflict_visualizer`. Its [scene](../../../algorithms/postfoundationscrisis/merge_conflict_visualizer.tscn) and [implementation](../../../algorithms/postfoundationscrisis/merge_conflict_visualizer.gd) supply the behaviour described here.

This follows Applied Ethics: choosing an arrangement made its assumptions available for inspection. Here four stored arrangements let us compare preserving, suppressing and separating a disagreement. Situated Computation next asks where the resulting claims come from.

The artifact still defaults to a passive `merge=junction` in other placements. This hall uses `merge_conflict_visualizer:180:0:1#merge:junction#interactive:true` at (4,4). An independent console presents JUNCTION, OVERLAP, RESOLVED and FORK. MARKER toggles only the glow; it does not rebuild or move the branches. Its choice survives a change of arrangement.

`_build_all()` selects the geometry. `apply_grid_config()` validates the selection, then rebuilds only the nodes owned by the visualization. External labels and the console survive. Each interactive branch has a box collision matching its size and rotation. Branch names use baked text plates; B's plate remains beside the short stump. Other placements keep their previous passive geometry and labels.

The display uses transformations already encountered in the book. JUNCTION leaves 0.6 m between upright boxes. OVERLAP rotates each 1.8 m box inward by 14 degrees about its foot, with the centre lines crossing at about 1.60 m. FORK rotates them outward by 18 degrees. RESOLVED moves A to the centre and gives B a height of 0.2 m. `_process()` varies the marker's emission with sine. None of these operations executes a logical rule.


## Operation to read after the encounter

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

The MERGE panel exposes JUNCTION, OVERLAP, RESOLVED and FORK. In RESOLVED, A keeps its full height and takes the centre; B becomes a labelled stump. Return to OVERLAP to recover both full-height branches. This is an authored picture of a decision, not a proof that the decision was warranted.

## What to compare

Read branch A and branch B and locate the light between them. Give each branch a concrete report about one door, including a time and a source. Decide whether your reports actually contradict each other before proposing a resolution.

JUNCTION keeps two separate upright pillars and a pulsing marker. OVERLAP leans them into a shared volume; FORK leans them apart. MARKER hides or reveals the glow without moving either branch. The sculpture displays relations; it does not run a merge algorithm or derive logical consequences.

## Limits and next test

Add a small inspectable inference table with a contradictory pair and an unrelated proposition. Require the visitor to predict which consequences follow. Compare that with preserving two source-tagged reports, so storage and inference remain distinct lessons.

The controlled museum probe checks button callbacks, selected reach, oriented-box overlap and selected walking routes. It does not establish headset readability, comfort or Quest frame rate. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Paraconsistent_Engineering/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.

The retained rhizome vault uses `#ground_top:0` here, making its ground plate flush with the museum floor. Its default remains 0.03 m in other placements. The vault retains its original position and scale; its broad footprint still extends beyond this hall and needs a separate architectural placement pass.
