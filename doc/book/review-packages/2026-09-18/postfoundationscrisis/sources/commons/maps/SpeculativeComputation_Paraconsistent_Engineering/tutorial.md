# What disappears when a disagreement is declared resolved?

Different positions can produce different requirements. Preserving the requirements is the first step towards inspecting their conflict.

<!-- @merge_conflict_visualizer -->

Read branch A and branch B and locate the light between them. Give each branch a concrete report about one door, including a time and a source. Decide whether your reports actually contradict each other before proposing a resolution.

The placed junction keeps two upright pillars and a pulsing marker. It displays a relation; it does not run a merge algorithm or derive logical consequences.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

There is a second arrangement in the source that this placement does not show. In resolved, A keeps its full height and B becomes a labelled stump. The two builder calls make resolution visible as a change in what remains. That is an authored picture of a decision, not a proof that the decision was warranted.

[Implementation](../../../algorithms/postfoundationscrisis/merge_conflict_visualizer.gd). This is an excerpt from the artifact, not a standalone program.

Two stored reports need not be a contradiction: they might concern different doors or different times. Preserving sources helps investigate that difference. It does not by itself change the rules of inference. The paraconsistent question is narrower: when both P and not-P are admitted, can unrelated conclusions still be refused? The sculpture makes room for that question but cannot answer it through overlapping meshes. Its unresolved glow should invite investigation rather than make conflict desirable in every case.

<!-- @ -->

To investigate disagreement we need to know where each claim came from.

## Next experiment — not yet a visitor control

Add a small inspectable inference table with a contradictory pair and an unrelated proposition. Require the visitor to predict which consequences follow. Compare that with preserving two source-tagged reports, so storage and inference remain distinct lessons.
