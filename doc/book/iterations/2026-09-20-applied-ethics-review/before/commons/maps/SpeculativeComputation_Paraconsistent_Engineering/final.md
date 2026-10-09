# Keeping the disagreement visible

Must one account disappear before two accounts can share a system?

<!-- @merge_conflict_visualizer -->

Trace branch A and branch B towards the lit junction. Inspect what remains visible on either side of that meeting point. Before deciding which branch should win, give each one a source and a reason to have arrived there.

The sculpture keeps two versions present around a conflict marker. It does not merge actual files or execute rules of logical inference. Its useful first gesture is spatial: an unresolved relation can be represented without erasing the parts that made the relation difficult.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

There is a second arrangement in the source that this placement does not show. In resolved, A keeps its full height and B becomes a labelled stump. The two builder calls make resolution visible as a change in what remains. That is an authored picture of a decision, not a proof that the decision was warranted.

Try a concrete disagreement. One report says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door’s identity may reveal that they concern different doors. Preserving provenance gives us ways to investigate before treating every difference as a contradiction about the same thing at the same time.

Formal paraconsistency concerns the inference rules themselves. In a paraconsistent logic, a contradiction need not license an arbitrary conclusion. It does not mean accepting every claim or abandoning the distinction between supported and unsupported inference. [Basu and Roy’s research paper starts from this failure of explosion when developing more general definitions.](https://arxiv.org/abs/2112.00357)

The current junction is an analogy for retaining a conflict, not a demonstration of that formal property. The next useful addition would expose a small rule table: after entering both a proposition and its negation, which consequences remain available, and which unrelated conclusion still cannot be derived?

Return to the pillars and imagine a resolution that shortens one to a stump. What information should remain so the decision can later be reconsidered? Keeping a source, a date and the rejected alternative does not make revision automatic, but it prevents a settled display from hiding how settlement occurred.

<!-- @ -->

Situated computation takes up that provenance. Four panels will judge one subject differently, and their positions will become part of what the judgement tells you.
