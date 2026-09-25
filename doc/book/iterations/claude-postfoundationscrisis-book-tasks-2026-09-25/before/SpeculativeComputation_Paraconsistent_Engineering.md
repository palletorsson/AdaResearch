# Keeping the disagreement visible

Must one account disappear before two accounts can share a system?

<!-- @merge_conflict_visualizer -->

Trace branch A and branch B towards the lit junction. Look from the side. The light hangs between them, but do the branches actually meet? Press MARKER to take the glow away. Before deciding which branch should win, give each one a source and a reason to have arrived there.

Press OVERLAP. The feet keep their places while the branches lean inward and pass through one another. Walk around the crossing. Nothing has been cut to make room. The renderer lets both forms remain; deciding what their meeting means is still ahead of us.

The sculpture keeps two versions present around a conflict marker. It does not merge actual files or execute rules of logical inference. Its useful first gesture is spatial: an unresolved relation can be represented without erasing the parts that made the relation difficult.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

Before pressing RESOLVED, choose what you would keep. Then look down for B. A keeps its full height and takes the centre; B becomes a labelled stump. Did the decision agree with yours? The two builder calls make resolution visible as a change in what remains. That is an authored picture of a decision, not a proof that the decision was warranted.

Press FORK. Both branches regain their height and lean apart. If the marker is visible, it has dropped between their feet. Distance has changed; no new reason has been given for either account. Return to OVERLAP when you want to see what settlement shortened.

Try a concrete disagreement. One report says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door’s identity may reveal that they concern different doors. Preserving provenance gives us ways to investigate before treating every difference as a contradiction about the same thing at the same time.

Formal paraconsistency concerns the inference rules themselves. In a paraconsistent logic, a contradiction need not license an arbitrary conclusion. It does not mean accepting every claim or abandoning the distinction between supported and unsupported inference. [Basu and Roy’s research paper starts from this failure of explosion when developing more general definitions.](https://arxiv.org/abs/2112.00357)

The current junction is an analogy for retaining a conflict, not a demonstration of that formal property. The next useful addition would expose a small rule table: after entering both a proposition and its negation, which consequences remain available, and which unrelated conclusion still cannot be derived?

Return to RESOLVED and find the small name beside B. A label remains, but it tells us little about what has been lost. What information should remain so the decision can later be reconsidered? Keeping a source, a date and the rejected alternative does not make revision automatic, but it prevents a settled display from hiding how settlement occurred.

<!-- @ -->

Situated computation takes up that provenance. Four panels will judge one subject differently, and their positions will become part of what the judgement tells you.
